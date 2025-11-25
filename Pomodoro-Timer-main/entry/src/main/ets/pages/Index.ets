import { promptAction, router } from '@kit.ArkUI';
import dataPreferences from '@ohos.data.preferences';
import { TimerCard } from '../components/TimerCard';
import { TaskItem } from '../components/TaskItem';
import { HttpService } from '../common/HttpService';

interface Task {
  id: number;
  title: string;
  completed: boolean;
  pomodoros: number;
  todayPomodoros: number;
  lastPomodoroDate: string;
}

interface FocusHistoryRecord {
  seconds: number;
  taskIds: number[];
}

// 添加主题颜色接口
interface ThemeColors {
  primary: string;
  secondary: string;
  background: string;
  cardBg: string;
  textPrimary: string;
  textSecondary: string;
}

@Entry
@Component
struct Index {
  @State remainingTime: number = 25 * 60;
  @State isRunning: boolean = false;
  @State isWorkTime: boolean = true;
  @State tasks: Task[] = [];
  @State newTask: string = '';
  @State currentTaskId: number = -1;
  @State totalPomodoros: number = 0;
  @State todayPomodoros: number = 0;
  @State showAddTask: boolean = false;
  @State todayDate: string = new Date().toDateString();
  @State refreshFlag: number = 0;
  private focusHistory: Record<string, FocusHistoryRecord> = {};
  private currentSessionSeconds: number = 0;
  private timer: number = 0;
  private preferences: dataPreferences.Preferences | null = null;
  // 添加 dialogController
  dialogController: CustomDialogController = new CustomDialogController({
    builder: this.DialogBuilder,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    customStyle: true,
    autoCancel: true,
    cancel: () => {
      this.showAddTask = false;
    }
  });
  // 添加删除对话框控制器
  deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: this.DeleteDialogBuilder,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    customStyle: true,
    autoCancel: true
  });
  // 当前要删除的任务ID
  @State taskToDelete: Task | null = null;

  // 定义对话框内容构建器
  @Builder
  DialogBuilder() {
    Column() {
      Text('添加任务')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 16 })

      TextInput({ placeholder: '输入任务名称' })
        .width('90%')
        .height(50)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.newTask = value;
        })

      Row() {
        Button('取消')
          .width('40%')
          .height(40)
          .backgroundColor(this.themeColors.textSecondary)
          .margin({ top: 20, right: 8 })
          .onClick(() => {
            this.dialogController.close();
            this.showAddTask = false;
          })

        Button('添加')
          .width('40%')
          .height(40)
          .backgroundColor(this.themeColors.primary)
          .margin({ top: 20, left: 8 })
          .onClick(() => {
            if (this.newTask.trim()) {
              // 检查任务名称是否重复
              if (this.isTaskNameDuplicate(this.newTask.trim())) {
                promptAction.showToast({
                  message: '任务名称已存在',
                  duration: 2000,
                });
                return;
              }
              this.createTask(this.newTask);
              this.newTask = '';
              this.dialogController.close();
              this.showAddTask = false;
            }
          })
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('90%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(24)
  }

  // 定义删除确认对话框内容
  @Builder
  DeleteDialogBuilder() {
    Column() {
      Text('确认删除')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 16 })

      Text(this.taskToDelete ? `是否删除任务"${this.taskToDelete.title}"？` : '')
        .fontSize(16)
        .fontColor(this.themeColors.textSecondary)
        .margin({ bottom: 20 })
        .textAlign(TextAlign.Center)

      Row() {
        Button('取消')
          .width('40%')
          .height(40)
          .backgroundColor(this.themeColors.textSecondary)
          .margin({ top: 20, right: 8 })
          .onClick(() => {
            this.deleteDialogController.close();
            this.taskToDelete = null;
          })

        Button('删除')
          .width('40%')
          .height(40)
          .backgroundColor(this.themeColors.primary)
          .margin({ top: 20, left: 8 })
          .onClick(() => {
            if (this.taskToDelete) {
              this.deleteTask(this.taskToDelete);
            }
            this.deleteDialogController.close();
            this.taskToDelete = null;
          })
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('90%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(24)
  }

  // 添加检查任务名称是否重复的方法
  private isTaskNameDuplicate(taskName: string): boolean {
    return this.tasks.some(task => task.title.toLowerCase() === taskName.toLowerCase());
  }

  async aboutToAppear() {
    try {
      // 获取preferences实例
      const context = getContext(this);
      this.preferences = await dataPreferences.getPreferences(context, 'PomodoroData');

      // 加载保存的数据
      const tasksStr = await this.preferences.get('tasks', '[]');
      this.tasks = JSON.parse(tasksStr as string);
      this.totalPomodoros = await this.preferences.get('totalPomodoros', 0) as number;
      const focusHistoryStr = await this.preferences.get('focusHistory', '{}');
      this.focusHistory = JSON.parse(focusHistoryStr as string);

      // 初始化今日总番茄数
      this.updateTodayTotal();
    } catch (error) {
      console.error('Failed to load data:', error);
    }
  }

  // 添加保存数据的方法
  private async saveData() {
    if (this.preferences) {
      try {
        await this.preferences.put('tasks', JSON.stringify(this.tasks));
        await this.preferences.put('totalPomodoros', this.totalPomodoros);
        await this.preferences.flush();
      } catch (error) {
        console.error('Failed to save data:', error);
      }
    }
  }

  // 修改主题颜色定义，添加类型声明
  readonly themeColors: ThemeColors = {
    primary: '#FF6B6B', // 番茄红
    secondary: '#4ECDC4', // 清新青
    background: '#F7F7F7', // 浅灰背景
    cardBg: '#FFFFFF', // 卡片背景
    textPrimary: '#2D3436', // 主要文字
    textSecondary: '#636E72'// 次要文字
  }

  @Builder
  TimerSection() {
    TimerCard({
      remainingTime: this.remainingTime,
      isRunning: this.isRunning,
      isWorkTime: this.isWorkTime,
      primaryColor: this.themeColors.primary,
      secondaryColor: this.themeColors.secondary,
      cardBg: this.themeColors.cardBg,
      textSecondary: this.themeColors.textSecondary,
      onStartClick: (): void => {
        this.toggleTimer();
      },
      onResetClick: (): void => {
        this.resetTimer();
      }
    })
  }

  @Builder
  TaskSection() {
    Column() {
      Row() {
        Text('任务列表')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeColors.textPrimary)

        Blank()

        Button('+')
          .width(50)
          .height(40)
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.themeColors.primary)
          .borderRadius(20)
          .onClick(() => {
            this.showAddTask = true;
            this.dialogController.open();
          })
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 16,
        bottom: 8
      })

      List() {
        ForEach(this.tasks, (task: Task) => {
          ListItem() {
            TaskItem({
              task: task,
              isActive: this.currentTaskId === task.id,
              primaryColor: this.themeColors.primary,
              cardBg: this.themeColors.cardBg,
              textPrimary: this.themeColors.textPrimary,
              textSecondary: this.themeColors.textSecondary,
              onTaskClick: (): void => {
                this.selectTask(task.id);
              },
              onDeleteClick: (): void => {
                this.showDeleteConfirm(task);
              }
            })
            .gesture(
              LongPressGesture()
                .onAction(() => {
                  this.showDeleteConfirm(task);
                })
            )
          }
          .margin({ bottom: 5 })
          .swipeAction({ end: this.DeleteButton(task) })
        })
      }
      .width('100%')
      .height('30%')
      .padding({ left: 16, right: 16 })
      .scrollBar(BarState.Auto)

      Row() {
        Text(`今日完成：${this.todayPomodoros} 🍅`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeColors.primary)

        Blank()

        Text(`总计完成：${this.totalPomodoros} 🍅`)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeColors.textSecondary)
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 12,
        bottom: 12
      })
      .backgroundColor(this.themeColors.cardBg)
      .borderRadius(16)
      .margin({ top: 16 })
    }
  }

  // 添加删除按钮构建器
  @Builder
  DeleteButton(task: Task) {
    Button() {
      Text('删除')
        .fontSize(16)
        .fontColor(Color.White)
    }
    .width(80)
    .height('100%')
    .backgroundColor(Color.Red)
    .onClick(() => {
      this.showDeleteConfirm(task);
    })
  }

  // 修改显示删除确认方法
  private showDeleteConfirm(task: Task) {
    this.taskToDelete = task;
    this.deleteDialogController.open();
  }

  // 添加删除任务方法
  private async deleteTask(delTask: Task) {
    // 如果删除的是当前选中的任务，清除选中状态
    if (delTask.id === this.currentTaskId) {
      this.currentTaskId = -1;
    }

    // 创建新的任务数组，排除要删除的任务
    const newTasks: Task[] = [];
    for (const task of this.tasks) {
      if (task.id !== delTask.id) {
        newTasks.push(task);
      }
    }

    // 更新任务列表
    this.tasks = newTasks;

    // 更新今日总番茄数
    this.updateTodayTotal();

    // 保存更改
    await this.saveData();

    // 显示删除成功提示
    promptAction.showToast({
      message: '任务 ' + delTask.title + ' 已删除',
      duration: 2000,
    });
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('番茄时钟')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
        
        Blank()
        
        // 导航按钮
        Row() {
          Button('统计')
            .width(60)
            .height(36)
            .fontSize(14)
            .backgroundColor(this.themeColors.secondary)
            .borderRadius(18)
            .margin({ right: 8 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/Statistics'
              });
            })
          
          Button('设置')
            .width(60)
            .height(36)
            .fontSize(14)
            .backgroundColor(this.themeColors.textSecondary)
            .borderRadius(18)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/Settings'
              });
            })
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.themeColors.cardBg)
      .borderRadius(16)
      .margin({ bottom: 16 })
      
      Scroll() {
        Column() {
          this.TimerSection()
          this.TaskSection()
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
    .padding(16)
  }

  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  private toggleTimer() {
    if (this.isRunning) {
      clearInterval(this.timer);
      void this.commitFocusTime();
    } else {
      this.currentSessionSeconds = 0;
      this.timer = setInterval(async () => {
        if (this.remainingTime > 0) {
          this.remainingTime--;
          if (this.isWorkTime) {
            this.currentSessionSeconds++;
          }
        } else {
          await this.completePomodoro();
        }
      }, 1000);
    }
    this.isRunning = !this.isRunning;
  }

  private resetTimer() {
    clearInterval(this.timer);
    void this.commitFocusTime();
    this.isRunning = false;
    this.currentSessionSeconds = 0;
    this.remainingTime = this.isWorkTime ? 25 * 60 : 5 * 60;
  }

  private async completePomodoro() {
    if (this.isWorkTime) {
      await this.commitFocusTime();
      this.totalPomodoros++;

      if (this.currentTaskId !== -1) {
        const taskIndex = this.tasks.findIndex(t => t.id === this.currentTaskId);
        if (taskIndex !== -1) {
          // 创建新的任务数组并更新任务
          const newTasks: Task[] = [];
          for (let i = 0; i < this.tasks.length; i++) {
            if (i === taskIndex) {
              const today = new Date().toDateString();
              newTasks.push({
                id: this.tasks[i].id,
                title: this.tasks[i].title,
                completed: this.tasks[i].completed,
                pomodoros: this.tasks[i].pomodoros + 1,
                todayPomodoros: this.tasks[i].lastPomodoroDate === today ?
                  this.tasks[i].todayPomodoros + 1 : 1,
                lastPomodoroDate: today
              });
            } else {
              newTasks.push(this.tasks[i]);
            }
          }

          // 更新任务数组
          this.tasks = newTasks;

          // 立即更新今日总番茄数
          this.updateTodayTotal();
        }
      }

      await this.saveData();

      promptAction.showToast({
        message: '太棒了！完成了一个🍅！',
        duration: 2000,
      });
    }
    this.switchMode();
  }

  // 更新今日总番茄数
  private updateTodayTotal() {
    const today = new Date().toDateString();
    let total = 0;
    for (const task of this.tasks) {
      if (task.lastPomodoroDate === today) {
        total += task.todayPomodoros;
      }
    }
    this.todayPomodoros = total;
  }

  private async commitFocusTime() {
    if (this.currentSessionSeconds <= 0 || !this.preferences) {
      this.currentSessionSeconds = 0;
      return;
    }
    let latestHistory: Record<string, FocusHistoryRecord> = {};
    try {
      const focusHistoryStr = await this.preferences.get('focusHistory', '{}');
      latestHistory = JSON.parse(focusHistoryStr as string);
    } catch (error) {
      console.error('Failed to reload focus history:', error);
      latestHistory = {};
    }

    const today = new Date().toDateString();
    if (!latestHistory[today]) {
      latestHistory[today] = {
        seconds: 0,
        taskIds: []
      };
    }
    latestHistory[today].seconds += this.currentSessionSeconds;
    if (this.currentTaskId !== -1 && latestHistory[today].taskIds.indexOf(this.currentTaskId) === -1) {
      latestHistory[today].taskIds.push(this.currentTaskId);
    }

    try {
      await this.preferences.put('focusHistory', JSON.stringify(latestHistory));
      await this.preferences.flush();
      this.focusHistory = latestHistory;
    } catch (error) {
      console.error('Failed to save focus history:', error);
    } finally {
      this.currentSessionSeconds = 0;
    }
  }

  private switchMode() {
    this.isWorkTime = !this.isWorkTime;
    this.remainingTime = this.isWorkTime ? 25 * 60 : 5 * 60;
    this.resetTimer();
  }

  private selectTask(id: number) {
    this.currentTaskId = id;
  }

  private async createTask(title: string) {
    const newTask: Task = {
      id: Date.now(),
      title: title,
      completed: false,
      pomodoros: 0,
      todayPomodoros: 0,
      lastPomodoroDate: new Date().toDateString()
    };

    // 创建新数组并添加任务
    const newTasks: Task[] = [];
    for (const task of this.tasks) {
      newTasks.push(task);
    }
    newTasks.push(newTask);

    this.tasks = newTasks;
    await this.saveData();
  }

  aboutToDisappear() {
    clearInterval(this.timer);
    void this.commitFocusTime();
    if (this.preferences) {
      this.preferences.flush();
    }
  }
}
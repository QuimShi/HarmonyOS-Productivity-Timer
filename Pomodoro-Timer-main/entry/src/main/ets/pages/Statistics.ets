import { router } from '@kit.ArkUI';
import dataPreferences from '@ohos.data.preferences';
import { Task } from '../models/TaskModel';

/**
 * 统计数据接口
 */
interface StatisticsData {
  date: string;
  pomodoros: number;
  tasks: number;
  focusTime: number; // 分钟
}

/**
 * 统计页面组件
 * 展示番茄钟使用数据统计，包括图表展示
 */
@Entry
@Component
struct Statistics {
  @State statisticsData: StatisticsData[] = [];
  @State totalPomodoros: number = 0;
  @State totalFocusTime: number = 0;
  @State totalTasks: number = 0;
  @State weekData: StatisticsData[] = [];
  private preferences: dataPreferences.Preferences | null = null;

  async aboutToAppear(): Promise<void> {
    await this.loadStatisticsData();
    this.calculateWeekData();
  }

  /**
   * 加载统计数据
   */
  private async loadStatisticsData(): Promise<void> {
    try {
      const context = getContext(this);
      this.preferences = await dataPreferences.getPreferences(context, 'PomodoroData');
      
      const tasksStr = await this.preferences.get('tasks', '[]');
      const tasks: Task[] = JSON.parse(tasksStr as string);

      // 优先根据任务数据计算统计信息，保证与主界面保持一致
      let totalPomodoros: number = 0;
      tasks.forEach((task: Task) => {
        totalPomodoros += task.pomodoros;
      });

      this.totalTasks = tasks.length;
      this.totalPomodoros = totalPomodoros;
      this.totalFocusTime = this.totalPomodoros * 25; // 每个番茄钟25分钟
      
      // 生成最近7天的数据
      this.generateWeekStatistics(tasks);
    } catch (error) {
      console.error('Failed to load statistics:', error);
    }
  }

  /**
   * 生成最近7天的统计数据
   */
  private generateWeekStatistics(tasks: Task[]): void {
    const weekData: StatisticsData[] = [];
    const today = new Date();
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const dateStr = date.toDateString();
      
      let dayPomodoros = 0;
      let dayTasks = 0;
      
      tasks.forEach((task: Task) => {
        if (task.lastPomodoroDate === dateStr) {
          dayPomodoros += task.todayPomodoros;
          dayTasks++;
        }
      });
      
      weekData.push({
        date: dateStr,
        pomodoros: dayPomodoros,
        tasks: dayTasks,
        focusTime: dayPomodoros * 25
      });
    }
    
    this.weekData = weekData;
  }

  /**
   * 计算周数据
   */
  private calculateWeekData(): void {
    // 根据最近7天数据重新计算汇总信息，保证顶部统计与图表一致
    let totalPomodoros: number = 0;
    let totalTasks: number = 0;

    this.weekData.forEach((item: StatisticsData) => {
      totalPomodoros += item.pomodoros;
      totalTasks += item.tasks;
    });

    this.totalPomodoros = totalPomodoros;
    this.totalTasks = totalTasks;
    this.totalFocusTime = this.totalPomodoros * 25; // 每个番茄钟25分钟
  }

  /**
   * 格式化日期显示
   */
  private formatDate(dateStr: string): string {
    const date = new Date(dateStr);
    const month = date.getMonth() + 1;
    const day = date.getDate();
    return `${month}/${day}`;
  }

  /**
   * 获取最大番茄数（用于图表缩放）
   */
  private getMaxPomodoros(): number {
    if (this.weekData.length === 0) return 1;
    const max = Math.max(...this.weekData.map((d: StatisticsData) => d.pomodoros));
    return max > 0 ? max : 1;
  }

  /**
   * 构建统计卡片
   */
  @Builder
  StatCard(title: string, value: string | number, icon: string): void {
    Column() {
      Text(icon)
        .fontSize(32)
        .margin({ bottom: 8 })
      
      Text(title)
        .fontSize(14)
        .fontColor('#636E72')
        .margin({ bottom: 4 })
      
      Text(`${value}`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF6B6B')
    }
    .width('30%')
    .height(120)
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 8,
      color: '#00000010',
      offsetY: 2
    })
  }

  /**
   * 构建柱状图
   */
  @Builder
  BarChart(): void {
    Column() {
      Text('最近7天番茄钟统计')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2D3436')
        .margin({ bottom: 20 })
      
      Row() {
        ForEach(this.weekData, (item: StatisticsData, index: number) => {
          Column() {
            // 柱状图
            Column()
              .width(30)
              .height(item.pomodoros * 100 / this.getMaxPomodoros())
              .backgroundColor('#FF6B6B')
              .borderRadius(4)
              .margin({ bottom: 8 })
            
            // 数值标签
            Text(`${item.pomodoros}`)
              .fontSize(12)
              .fontColor('#2D3436')
              .margin({ bottom: 4 })
            
            // 日期标签
            Text(this.formatDate(item.date))
              .fontSize(10)
              .fontColor('#636E72')
          }
          .width('14%')
          .height(200)
          .justifyContent(FlexAlign.End)
          .alignItems(HorizontalAlign.Center)
        })
      }
      .width('100%')
      .height(200)
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 16 })
  }

  /**
   * 构建折线图（使用Canvas模拟）
   */
  @Builder
  LineChart(): void {
    Column() {
      Text('专注时间趋势')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2D3436')
        .margin({ bottom: 20 })
      
      // 使用Row和Column模拟折线图
      Stack() {
        // 背景网格
        Column() {
          ForEach([0, 1, 2, 3, 4], (i: number) => {
            Divider()
              .color('#E0E0E0')
              .strokeWidth(1)
              .margin({ top: 40 })
          })
        }
        .width('100%')
        .height(180)
        
        // 数据点连线（使用视觉元素模拟）
        Row() {
          ForEach(this.weekData, (item: StatisticsData, index: number) => {
            Column() {
              // 数据点
              Circle()
                .width(12)
                .height(12)
                .fill('#FF6B6B')
                .margin({ bottom: 4 })
              
              Text(`${item.focusTime}分钟`)
                .fontSize(10)
                .fontColor('#636E72')
            }
            .width('14%')
            .height(180)
            .justifyContent(FlexAlign.End)
            .alignItems(HorizontalAlign.Center)
          })
        }
        .width('100%')
        .height(180)
      }
      .width('100%')
      .height(180)
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 16 })
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('←')
          .width(40)
          .height(40)
          .fontSize(20)
          .backgroundColor('#F7F7F7')
          .borderRadius(20)
          .margin({ right: 12 })
          .onClick(() => {
            router.back();
          })
        
        Text('数据统计')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2D3436')
        
        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      
      Scroll() {
        Column() {
          // 统计卡片区域
          Row() {
            this.StatCard('总番茄数', this.totalPomodoros, '🍅')
            this.StatCard('总专注时间', `${this.totalFocusTime}分钟`, '⏱️')
            this.StatCard('任务总数', this.totalTasks, '📋')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
          .margin({ top: 16 })
          
          // 柱状图
          this.BarChart()
          
          // 折线图
          this.LineChart()
          
          // 详细数据列表
          Column() {
            Text('详细数据')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#2D3436')
              .margin({ bottom: 16 })
            
            ForEach(this.weekData, (item: StatisticsData) => {
              Row() {
                Column() {
                  Text(this.formatDate(item.date))
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#2D3436')
                  
                  Text(`${item.tasks}个任务`)
                    .fontSize(12)
                    .fontColor('#636E72')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                
                Blank()
                
                Column() {
                  Text(`${item.pomodoros} 🍅`)
                    .fontSize(16)
                    .fontColor('#FF6B6B')
                    .fontWeight(FontWeight.Medium)
                  
                  Text(`${item.focusTime}分钟`)
                    .fontSize(12)
                    .fontColor('#636E72')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.End)
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#F7F7F7')
              .borderRadius(12)
              .margin({ bottom: 8 })
            })
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .margin({ top: 16, bottom: 32 })
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F7F7')
  }
}

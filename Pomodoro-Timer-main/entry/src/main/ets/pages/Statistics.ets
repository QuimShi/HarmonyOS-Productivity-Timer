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

interface FocusHistoryRecord {
  seconds: number;
  taskIds: number[];
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
  @State totalFocusSeconds: number = 0;
  @State totalTasks: number = 0;
  @State weekData: StatisticsData[] = [];
  private focusHistory: Record<string, FocusHistoryRecord> = {};
  private preferences: dataPreferences.Preferences | null = null;

  async aboutToAppear(): Promise<void> {
    await this.loadStatisticsData();
  }
  
  // 每次页面显示时重新加载数据
  async onPageShow(): Promise<void> {
    await this.loadStatisticsData();
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

      const focusHistoryStr = await this.preferences.get('focusHistory', '{}');
      this.focusHistory = JSON.parse(focusHistoryStr as string);
      
      // 生成最近7天的数据
      this.generateWeekStatistics();

      this.updateSummaryStats(tasks);
    } catch (error) {
      console.error('Failed to load statistics:', error);
    }
  }

  /**
   * 生成最近7天的统计数据
   */
  private generateWeekStatistics(): void {
    const weekData: StatisticsData[] = [];
    const today = new Date();
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const dateStr = date.toDateString();

      const record = this.focusHistory[dateStr];
      const focusMinutes = record ? Math.floor(record.seconds / 60) : 0;
      const dayTasks = record ? record.taskIds.length : 0;
      
      weekData.push({
        date: dateStr,
        pomodoros: focusMinutes,
        tasks: dayTasks,
        focusTime: focusMinutes
      });
    }
    
    this.weekData = weekData;
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
   * 根据 focusHistory 与任务列表更新顶部统计
   */
  private updateSummaryStats(tasks: Task[]): void {
    let focusSecondsFromHistory = 0;
    const uniqueTaskIds: Set<number> = new Set();

    Object.values(this.focusHistory).forEach((record: FocusHistoryRecord | undefined) => {
      if (!record) {
        return;
      }
      focusSecondsFromHistory += record.seconds || 0;
      record.taskIds.forEach((id: number) => uniqueTaskIds.add(id));
    });

    this.totalFocusSeconds = focusSecondsFromHistory;
    this.totalPomodoros = tasks.reduce((sum: number, task: Task) => sum + task.pomodoros, 0);
    this.totalTasks = tasks.length > 0 ? tasks.length : uniqueTaskIds.size;
  }

  /**
   * 格式化总专注时间显示
   */
  private formatFocusTimeDisplay(seconds: number): string {
    if (seconds <= 0) {
      return '0分钟';
    }
    if (seconds < 60) {
      return `${seconds}秒`;
    }
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    if (secs === 0) {
      return `${mins}分钟`;
    }
    return `${mins}分${secs}秒`;
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
      Text('最近7天专注时长（分钟）')
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
        
        // 绘制连接线 - 使用简化的实现
        ForEach(this.weekData.slice(0, -1), (item: StatisticsData, index: number) => {
          Line()
            .startPoint([`${(index + 0.5) * (100 / this.weekData.length)}%`, 180 - item.focusTime])
            .endPoint([`${(index + 1.5) * (100 / this.weekData.length)}%`, 180 - this.weekData[index + 1].focusTime])
            .stroke('#FF6B6B')
            .strokeWidth(2)
        })
        
        // 数据点显示
        Row() {
          ForEach(this.weekData, (item: StatisticsData, index: number) => {
            Column() {
              // 数据点容器，控制垂直位置
              Stack() {
                Circle()
                  .width(12)
                  .height(12)
                  .fill('#FF6B6B')
              }
              .height(180 - item.focusTime)
              .alignContent(Alignment.End)
              
              // 数据标签
              Text(`${item.focusTime}分钟`)
                .fontSize(10)
                .fontColor('#636E72')
                .margin({ top: 4 })
            }
            .width('14%')
            .height(180)
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
          // 统计卡片区域已移除
          
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
                  Text(`${item.pomodoros} 分钟`)
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

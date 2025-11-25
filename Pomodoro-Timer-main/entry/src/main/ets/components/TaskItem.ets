import { Task } from '../models/TaskModel';

/**
 * 任务项组件
 * 封装任务列表项的显示和交互
 */
@Component
export struct TaskItem {
  @Prop task: Task;
  @Prop isActive: boolean = false;
  @Prop primaryColor: string = '#FF6B6B';
  @Prop cardBg: string = '#FFFFFF';
  @Prop textPrimary: string = '#2D3436';
  @Prop textSecondary: string = '#636E72';
  
  onTaskClick?: () => void;
  onDeleteClick?: () => void;

  build() {
    Row() {
      Column() {
        Row() {
          Text(this.task.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textPrimary)
            .decoration({
              type: this.task.completed ? TextDecorationType.LineThrough : TextDecorationType.None,
              color: this.textSecondary
            })

          Text(`今日：${this.task.todayPomodoros} 🍅`)
            .fontSize(14)
            .fontColor(this.textSecondary)
            .margin({ left: 20 })

          Text(`总计：${this.task.pomodoros} 🍅`)
            .fontSize(14)
            .fontColor(this.textSecondary)
            .margin({ left: 16 })
        }
        .margin({ top: 4 })
      }

      Blank()

      if (this.isActive) {
        Text('进行中')
          .fontColor(this.primaryColor)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.isActive ? '#FFF5F5' : this.cardBg)
    .borderRadius(16)
    .shadow({
      radius: 8,
      color: '#00000010',
      offsetY: 2
    })
    .onClick(() => {
      if (this.onTaskClick) {
        this.onTaskClick();
      }
    })
  }
}


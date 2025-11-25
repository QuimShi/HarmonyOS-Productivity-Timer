/**
 * 计时器卡片组件
 * 封装计时器显示和控制功能
 */
@Component
export struct TimerCard {
  @Prop remainingTime: number = 0;
  @Prop isRunning: boolean = false;
  @Prop isWorkTime: boolean = true;
  @Prop primaryColor: string = '#FF6B6B';
  @Prop secondaryColor: string = '#4ECDC4';
  @Prop cardBg: string = '#FFFFFF';
  @Prop textSecondary: string = '#636E72';
  
  onStartClick?: () => void;
  onResetClick?: () => void;

  /**
   * 格式化时间显示
   */
  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  build() {
    Column() {
      Stack() {
        // 背景圆环
        Circle()
          .width(200)
          .height(200)
          .fill(this.cardBg)
          .stroke(this.primaryColor)
          .strokeWidth(4)
          .opacity(0.1)

        // 进度圆环
        Circle()
          .width(200)
          .height(200)
          .fill('none')
          .stroke(this.primaryColor)
          .strokeWidth(8)

        Column() {
          Text(this.formatTime(this.remainingTime))
            .fontSize(64)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.primaryColor)

          Text(this.isWorkTime ? '专注时间' : '休息时间')
            .fontSize(20)
            .margin({ top: 8 })
            .fontColor(this.textSecondary)
        }
      }
      .margin({ top: 10, bottom: 30 })
      .animation({
        duration: 1000,
        curve: Curve.EaseInOut
      })

      Row() {
        Button(this.isRunning ? '暂停' : '开始')
          .width(140)
          .height(48)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.isRunning ? this.secondaryColor : this.primaryColor)
          .borderRadius(24)
          .onClick(() => {
            if (this.onStartClick) {
              this.onStartClick();
            }
          })

        Button('重置')
          .width(140)
          .height(48)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#636E72')
          .borderRadius(24)
          .margin({ left: 16 })
          .onClick(() => {
            if (this.onResetClick) {
              this.onResetClick();
            }
          })
      }
      .margin({ bottom: 10 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.cardBg)
    .borderRadius(32)
    .margin({ top: 35 })
  }
}


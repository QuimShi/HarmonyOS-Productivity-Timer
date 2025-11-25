import { router, promptAction } from '@kit.ArkUI';
import dataPreferences from '@ohos.data.preferences';

/**
 * 设置项接口
 */
interface SettingItem {
  title: string;
  value: string | number;
  type: 'switch' | 'number' | 'text';
}

/**
 * 设置页面组件
 * 提供应用配置选项
 */
@Entry
@Component
struct Settings {
  @State workDuration: number = 25; // 工作时间（分钟）
  @State restDuration: number = 5; // 休息时间（分钟）
  @State soundEnabled: boolean = true; // 声音提醒
  @State vibrationEnabled: boolean = true; // 震动提醒
  @State autoStartRest: boolean = false; // 自动开始休息
  @State showNotifications: boolean = true; // 显示通知
  private preferences: dataPreferences.Preferences | null = null;

  async aboutToAppear() {
    await this.loadSettings();
  }

  /**
   * 加载设置
   */
  private async loadSettings() {
    try {
      const context = getContext(this);
      this.preferences = await dataPreferences.getPreferences(context, 'PomodoroSettings');
      
      this.workDuration = await this.preferences.get('workDuration', 25) as number;
      this.restDuration = await this.preferences.get('restDuration', 5) as number;
      this.soundEnabled = await this.preferences.get('soundEnabled', true) as boolean;
      this.vibrationEnabled = await this.preferences.get('vibrationEnabled', true) as boolean;
      this.autoStartRest = await this.preferences.get('autoStartRest', false) as boolean;
      this.showNotifications = await this.preferences.get('showNotifications', true) as boolean;
    } catch (error) {
      console.error('Failed to load settings:', error);
    }
  }

  /**
   * 保存设置
   */
  private async saveSettings() {
    if (this.preferences) {
      try {
        await this.preferences.put('workDuration', this.workDuration);
        await this.preferences.put('restDuration', this.restDuration);
        await this.preferences.put('soundEnabled', this.soundEnabled);
        await this.preferences.put('vibrationEnabled', this.vibrationEnabled);
        await this.preferences.put('autoStartRest', this.autoStartRest);
        await this.preferences.put('showNotifications', this.showNotifications);
        await this.preferences.flush();
        
        promptAction.showToast({
          message: '设置已保存',
          duration: 2000,
        });
      } catch (error) {
        console.error('Failed to save settings:', error);
      }
    }
  }

  /**
   * 构建设置项
   */
  @Builder
  SettingItem(title: string, subtitle: string, value: boolean, onToggle: () => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2D3436')
        
        Text(subtitle)
          .fontSize(12)
          .fontColor('#636E72')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor('#FF6B6B')
        .onChange((isOn: boolean) => {
          onToggle();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  /**
   * 构建数字输入项
   */
  @Builder
  NumberSettingItem(title: string, subtitle: string, value: number, min: number, max: number, onChange: (value: number) => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2D3436')
        
        Text(subtitle)
          .fontSize(12)
          .fontColor('#636E72')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      Row() {
        Button('-')
          .width(40)
          .height(40)
          .fontSize(18)
          .backgroundColor('#F7F7F7')
          .borderRadius(8)
          .enabled(value > min)
          .onClick(() => {
            if (value > min) {
              onChange(value - 1);
            }
          })
        
        Text(`${value}`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2D3436')
          .width(60)
          .textAlign(TextAlign.Center)
        
        Button('+')
          .width(40)
          .height(40)
          .fontSize(18)
          .backgroundColor('#F7F7F7')
          .borderRadius(8)
          .enabled(value < max)
          .onClick(() => {
            if (value < max) {
              onChange(value + 1);
            }
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  /**
   * 构建操作按钮
   */
  @Builder
  ActionButton(title: string, onClick: () => void) {
    Button(title)
      .width('100%')
      .height(48)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .backgroundColor('#FF6B6B')
      .borderRadius(12)
      .onClick(onClick)
      .margin({ bottom: 12 })
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
        
        Text('设置')
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
          // 时间设置
          Text('时间设置')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#2D3436')
            .margin({ top: 16, bottom: 12, left: 16 })
            .alignSelf(ItemAlign.Start)
          
          this.NumberSettingItem(
            '工作时间',
            '每个番茄钟的工作时长',
            this.workDuration,
            5,
            60,
            (value: number) => {
              this.workDuration = value;
              this.saveSettings();
            }
          )
          
          this.NumberSettingItem(
            '休息时间',
            '每个番茄钟后的休息时长',
            this.restDuration,
            1,
            30,
            (value: number) => {
              this.restDuration = value;
              this.saveSettings();
            }
          )
          
          // 提醒设置
          Text('提醒设置')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#2D3436')
            .margin({ top: 16, bottom: 12, left: 16 })
            .alignSelf(ItemAlign.Start)
          
          this.SettingItem(
            '声音提醒',
            '完成时播放提示音',
            this.soundEnabled,
            () => {
              this.soundEnabled = !this.soundEnabled;
              this.saveSettings();
            }
          )
          
          this.SettingItem(
            '震动提醒',
            '完成时震动提醒',
            this.vibrationEnabled,
            () => {
              this.vibrationEnabled = !this.vibrationEnabled;
              this.saveSettings();
            }
          )
          
          this.SettingItem(
            '显示通知',
            '在通知栏显示提醒',
            this.showNotifications,
            () => {
              this.showNotifications = !this.showNotifications;
              this.saveSettings();
            }
          )
          
          // 其他设置
          Text('其他设置')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#2D3436')
            .margin({ top: 16, bottom: 12, left: 16 })
            .alignSelf(ItemAlign.Start)
          
          this.SettingItem(
            '自动开始休息',
            '工作完成后自动开始休息',
            this.autoStartRest,
            () => {
              this.autoStartRest = !this.autoStartRest;
              this.saveSettings();
            }
          )
          
          // 操作按钮
          this.ActionButton('保存设置', () => {
            this.saveSettings();
          })
          
          this.ActionButton('恢复默认', () => {
            this.workDuration = 25;
            this.restDuration = 5;
            this.soundEnabled = true;
            this.vibrationEnabled = true;
            this.autoStartRest = false;
            this.showNotifications = true;
            this.saveSettings();
          })
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


/**
 * 应用常量定义
 * 统一管理应用中的常量值
 */
export class Constants {
  /**
   * 默认工作时间（分钟）
   */
  static readonly DEFAULT_WORK_DURATION: number = 25;

  /**
   * 默认休息时间（分钟）
   */
  static readonly DEFAULT_REST_DURATION: number = 5;

  /**
   * 主题颜色配置
   */
  static readonly THEME_COLORS = {
    PRIMARY: '#FF6B6B',        // 番茄红
    SECONDARY: '#4ECDC4',      // 清新青
    BACKGROUND: '#F7F7F7',     // 浅灰背景
    CARD_BG: '#FFFFFF',        // 卡片背景
    TEXT_PRIMARY: '#2D3436',   // 主要文字
    TEXT_SECONDARY: '#636E72'  // 次要文字
  };

  /**
   * 数据存储键名
   */
  static readonly STORAGE_KEYS = {
    TASKS: 'tasks',
    TOTAL_POMODOROS: 'totalPomodoros',
    WORK_DURATION: 'workDuration',
    REST_DURATION: 'restDuration',
    SOUND_ENABLED: 'soundEnabled',
    VIBRATION_ENABLED: 'vibrationEnabled',
    AUTO_START_REST: 'autoStartRest',
    SHOW_NOTIFICATIONS: 'showNotifications'
  };

  /**
   * 数据存储文件名
   */
  static readonly STORAGE_FILES = {
    POMODORO_DATA: 'PomodoroData',
    POMODORO_SETTINGS: 'PomodoroSettings'
  };
}


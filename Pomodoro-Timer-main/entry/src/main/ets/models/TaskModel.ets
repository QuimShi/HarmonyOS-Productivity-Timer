/**
 * 任务数据模型
 * 定义任务相关的数据结构和接口
 */

/**
 * 任务接口
 */
export interface Task {
  id: number;                    // 任务ID
  title: string;                 // 任务标题
  completed: boolean;            // 是否完成
  pomodoros: number;             // 总番茄数
  todayPomodoros: number;        // 今日番茄数
  lastPomodoroDate: string;      // 最后完成番茄的日期
}

/**
 * 任务管理类
 * 提供任务相关的业务逻辑
 */
export class TaskModel {
  /**
   * 创建新任务
   */
  static createTask(title: string): Task {
    return {
      id: Date.now(),
      title: title,
      completed: false,
      pomodoros: 0,
      todayPomodoros: 0,
      lastPomodoroDate: new Date().toDateString()
    };
  }

  /**
   * 更新任务的番茄数
   */
  static updateTaskPomodoro(task: Task): Task {
    const today = new Date().toDateString();
    return {
      id: task.id,
      title: task.title,
      completed: task.completed,
      pomodoros: task.pomodoros + 1,
      todayPomodoros: task.lastPomodoroDate === today ? task.todayPomodoros + 1 : 1,
      lastPomodoroDate: today
    };
  }

  /**
   * 检查任务名称是否重复
   */
  static isTaskNameDuplicate(tasks: Task[], taskName: string): boolean {
    return tasks.some(task => task.title.toLowerCase() === taskName.toLowerCase());
  }
}


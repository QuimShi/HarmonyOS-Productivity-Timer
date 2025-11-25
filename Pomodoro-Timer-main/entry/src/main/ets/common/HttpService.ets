import http from '@ohos.net.http';

/**
 * HTTP响应接口
 */
export interface HttpResponse<T = ESObject> {
  code: number;
  message: string;
  data: T;
}

/**
 * Mock统计数据接口
 */
interface MockStatisticsData {
  totalPomodoros: number;
  totalFocusTime: number;
  totalTasks: number;
  weekData: WeekDataItem[];
}

/**
 * 周数据项接口
 */
interface WeekDataItem {
  date: string;
  pomodoros: number;
  tasks: number;
  focusTime: number;
}

/**
 * Mock任务数据接口
 */
interface MockTaskData {
  id: number;
  title: string;
  completed: boolean;
  pomodoros: number;
  todayPomodoros: number;
}

/**
 * Mock设置数据接口
 */
interface MockSettingsData {
  workDuration: number;
  restDuration: number;
  soundEnabled: boolean;
  vibrationEnabled: boolean;
}

/**
 * HTTP服务类
 * 封装网络请求功能，支持Mock数据
 */
export class HttpService {
  private static baseUrl: string = 'http://172.20.10.8:8080/api'; // 本地服务器地址
  private static mockMode: boolean = false; // Mock模式开关

  /**
   * 设置Mock模式
   */
  static setMockMode(enabled: boolean): void {
    HttpService.mockMode = enabled;
  }

  /**
   * 设置基础URL
   */
  static setBaseUrl(url: string): void {
    HttpService.baseUrl = url;
  }

  /**
   * GET请求
   */
  static async get<T = ESObject>(url: string, params?: Record<string, string>): Promise<HttpResponse<T>> {
    if (HttpService.mockMode) {
      return HttpService.mockRequest<T>(url, 'GET', params);
    }

    try {
      const httpRequest = http.createHttp();
      let fullUrl = `${HttpService.baseUrl}${url}`;
      
      if (params) {
        const queryString = Object.keys(params)
          .map((key: string) => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`)
          .join('&');
        fullUrl += `?${queryString}`;
      }

      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        }
      });

      httpRequest.destroy();
      return JSON.parse(response.result.toString()) as HttpResponse<T>;
    } catch (error) {
      console.error('GET request failed:', error);
      throw new Error('GET request failed');
    }
  }

  /**
   * POST请求
   */
  static async post<T = ESObject>(url: string, data?: ESObject): Promise<HttpResponse<T>> {
    if (HttpService.mockMode) {
      return HttpService.mockRequest<T>(url, 'POST', data);
    }

    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(`${HttpService.baseUrl}${url}`, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify(data)
      });

      httpRequest.destroy();
      return JSON.parse(response.result.toString()) as HttpResponse<T>;
    } catch (error) {
      console.error('POST request failed:', error);
      throw new Error('POST request failed');
    }
  }

  /**
   * Mock数据请求
   */
  private static async mockRequest<T>(url: string, method: string, params?: ESObject): Promise<HttpResponse<T>> {
    // 模拟网络延迟
    await new Promise<void>((resolve: () => void) => setTimeout(resolve, 300));

    // Mock数据 - 使用明确的类型
    const statisticsResponse: HttpResponse<MockStatisticsData> = {
      code: 200,
      message: 'success',
      data: {
        totalPomodoros: 156,
        totalFocusTime: 3900,
        totalTasks: 12,
        weekData: [
          { date: '2024-01-01', pomodoros: 8, tasks: 3, focusTime: 200 },
          { date: '2024-01-02', pomodoros: 6, tasks: 2, focusTime: 150 },
          { date: '2024-01-03', pomodoros: 10, tasks: 4, focusTime: 250 },
          { date: '2024-01-04', pomodoros: 7, tasks: 3, focusTime: 175 },
          { date: '2024-01-05', pomodoros: 9, tasks: 3, focusTime: 225 },
          { date: '2024-01-06', pomodoros: 5, tasks: 2, focusTime: 125 },
          { date: '2024-01-07', pomodoros: 8, tasks: 3, focusTime: 200 }
        ]
      }
    };

    const tasksResponse: HttpResponse<MockTaskData[]> = {
      code: 200,
      message: 'success',
      data: [
        { id: 1, title: '学习HarmonyOS开发', completed: false, pomodoros: 12, todayPomodoros: 3 },
        { id: 2, title: '完成课程论文', completed: false, pomodoros: 8, todayPomodoros: 2 },
        { id: 3, title: '准备项目答辩', completed: true, pomodoros: 15, todayPomodoros: 0 }
      ]
    };

    const settingsResponse: HttpResponse<MockSettingsData> = {
      code: 200,
      message: 'success',
      data: {
        workDuration: 25,
        restDuration: 5,
        soundEnabled: true,
        vibrationEnabled: true
      }
    };

    const defaultResponse: HttpResponse<ESObject> = {
      code: 200,
      message: 'success',
      data: {}
    };

    // 根据URL返回对应的Mock数据
    if (url === '/statistics') {
      return statisticsResponse as HttpResponse<T>;
    } else if (url === '/tasks') {
      return tasksResponse as HttpResponse<T>;
    } else if (url === '/settings') {
      return settingsResponse as HttpResponse<T>;
    } else {
      return defaultResponse as HttpResponse<T>;
    }
  }
}

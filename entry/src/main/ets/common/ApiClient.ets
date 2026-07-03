import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

/**
 * API 响应格式
 */
export class ApiResponse<T> {
  code: number = -1
  data: T | null = null
  message: string = ''
}

/**
 * Lumina API 客户端
 * 封装 @ohos.net.http 网络请求
 */
export class ApiClient {
  // 后端服务器地址 —— 模拟器用 10.0.2.2，真机改成电脑局域网IP
  static readonly BASE_URL: string = 'http://10.0.2.2:3000'

  // 认证 token（登录后设置）
  static authToken: string = ''

  /**
   * GET 请求
   */
  static async get<T>(path: string): Promise<ApiResponse<T>> {
    return ApiClient.request<T>('GET', path)
  }

  /**
   * POST 请求
   */
  static async post<T>(path: string, body?: Object): Promise<ApiResponse<T>> {
    return ApiClient.request<T>('POST', path, body)
  }

  /**
   * PUT 请求
   */
  static async put<T>(path: string, body?: Object): Promise<ApiResponse<T>> {
    return ApiClient.request<T>('PUT', path, body)
  }

  /**
   * 底层请求方法
   */
  private static async request<T>(method: string, path: string, body?: Object): Promise<ApiResponse<T>> {
    const client = http.createHttp()
    const url = ApiClient.BASE_URL + path

    try {
      const header: Record<string, string> = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }

      // 如果已登录，携带认证 token
      if (ApiClient.authToken) {
        header['Authorization'] = 'Bearer ' + ApiClient.authToken
      }

      const requestOpts: http.HttpRequestOptions = {
        method: method as http.RequestMethod,
        header: header,
        connectTimeout: 5000,
        readTimeout: 10000,
      }

      if (body) {
        requestOpts.extraData = JSON.stringify(body) as string | ArrayBuffer
      }

      const response = await client.request(url, requestOpts)
      client.destroy()

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as ApiResponse<T>
        return result
      } else {
        const resp: ApiResponse<T> = {
          code: -1,
          data: null,
          message: 'HTTP ' + response.responseCode.toString()
        }
        return resp
      }
    } catch (err) {
      client.destroy()
      const error = err as BusinessError
      const resp: ApiResponse<T> = {
        code: -1,
        data: null,
        message: error.message || '网络请求失败'
      }
      return resp
    }
  }
}

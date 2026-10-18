import http from '@ohos.net.http';
import { CookieManager } from './CookieManager';

export class HttpClient {
  private static baseUrl: string = "https://bbs.binmt.cc/";
  
  // 基于 MTF 安卓端的 UA 配置
  private static userAgent: string = "Mozilla/5.0 (Linux; Android 10; HarmonyOS) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36";

  static async request(method: http.RequestMethod, url: string, body?: any, extraHeaders?: Record<string, string>): Promise<string> {
    let httpRequest = http.createHttp();
    let fullUrl = url.startsWith('http') ? url : `${this.baseUrl}${url}`;
    
    let headers: Record<string, string> = {
      'User-Agent': this.userAgent,
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9',
      'Referer': 'https://bbs.binmt.cc/'
    };

    let cookie = CookieManager.get();
    if (cookie) {
      headers['Cookie'] = cookie;
    }

    if (extraHeaders) {
      Object.assign(headers, extraHeaders);
    }

    let options: http.HttpRequestOptions = {
      method: method,
      header: headers,
      expectDataType: http.HttpDataType.STRING,
      readTimeout: 15000,
      connectTimeout: 15000
    };

    if (method === http.RequestMethod.POST && body) {
      if (typeof body === 'string') {
        options.extraData = body;
      } else {
        // 模拟表单提交
        let formData = [];
        for (let key in body) {
          formData.push(`${encodeURIComponent(key)}=${encodeURIComponent(body[key])}`);
        }
        options.extraData = formData.join('&');
        headers['Content-Type'] = 'application/x-www-form-urlencoded';
      }
    }

    try {
      let response = await httpRequest.request(fullUrl, options);
      
      // 处理服务端下发的 Set-Cookie
      let setCookie = response.header['set-cookie'];
      if (setCookie) {
        let newCookieStr = typeof setCookie === 'string' ? setCookie : (setCookie as string[]).join('; ');
        // 简单合并更新 Cookie
        let currentCookie = CookieManager.get();
        if (!currentCookie) {
          CookieManager.save(newCookieStr);
        } else {
          // 这里简化处理，实际可能需要按 key 替换
          CookieManager.save(currentCookie + '; ' + newCookieStr);
        }
      }
      return response.result as string;
    } catch (error) {
      console.error('HttpClient Error:', JSON.stringify(error));
      throw error;
    } finally {
      httpRequest.destroy();
    }
  }

  static get(url: string, headers?: Record<string, string>): Promise<string> {
    return this.request(http.RequestMethod.GET, url, undefined, headers);
  }

  static post(url: string, body: any, headers?: Record<string, string>): Promise<string> {
    return this.request(http.RequestMethod.POST, url, body, headers);
  }
}

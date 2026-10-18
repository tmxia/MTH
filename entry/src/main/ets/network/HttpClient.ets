import http from '@ohos.net.http';
import { cookieManager } from './CookieManager';

export class HttpClient {
  private static baseUrl: string = "https://bbs.binmt.cc/";
  // 完全对齐安卓原版 ForumMediaClient 中的 UA
  private static userAgent: string = "Mozilla/5.0 (Linux; Android 10; HarmonyOS) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36";

  static async request(method: http.RequestMethod, url: string, body?: Record<string, string>, extraHeaders?: Record<string, string>): Promise<string> {
    let httpRequest = http.createHttp();
    let fullUrl = url.startsWith('http') ? url : HttpClient.baseUrl + url;
    
    let headers: Record<string, string> = {
      'User-Agent': HttpClient.userAgent,
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Referer': 'https://bbs.binmt.cc/forum.php' // 原版要求完整页面路径
    };

    let cookie = cookieManager.get();
    if (cookie) {
      headers['Cookie'] = cookie;
    }

    // 替代 Object.assign，手动遍历合并
    if (extraHeaders) {
      let keys = Object.keys(extraHeaders);
      for (let i = 0; i < keys.length; i++) {
        let k = keys[i];
        headers[k] = extraHeaders[k];
      }
    }

    let options: http.HttpRequestOptions = {
      method: method,
      header: headers,
      expectDataType: http.HttpDataType.STRING,
      readTimeout: 15000,
      connectTimeout: 15000
    };

    if (method === http.RequestMethod.POST && body) {
      let formData: string[] = [];
      let bodyKeys = Object.keys(body);
      for (let i = 0; i < bodyKeys.length; i++) {
        let k = bodyKeys[i];
        let val = body[k];
        formData.push(encodeURIComponent(k) + '=' + encodeURIComponent(val));
      }
      options.extraData = formData.join('&');
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }

    try {
      let response = await httpRequest.request(fullUrl, options);
      
      let setCookie = response.header['set-cookie'];
      if (setCookie) {
        let newCookieStr = '';
        if (typeof setCookie === 'string') {
          newCookieStr = setCookie;
        } else {
          newCookieStr = (setCookie as string[]).join('; ');
        }
        let currentCookie = cookieManager.get();
        if (!currentCookie) {
          await cookieManager.save(newCookieStr);
        } else {
          await cookieManager.save(currentCookie + '; ' + newCookieStr);
        }
      }
      return response.result as string;
    } catch (error) {
      throw new Error('Http Request Failed: ' + JSON.stringify(error));
    } finally {
      httpRequest.destroy();
    }
  }

  static get(url: string, headers?: Record<string, string>): Promise<string> {
    return HttpClient.request(http.RequestMethod.GET, url, undefined, headers);
  }

  static post(url: string, body: Record<string, string>, headers?: Record<string, string>): Promise<string> {
    return HttpClient.request(http.RequestMethod.POST, url, body, headers);
  }
}

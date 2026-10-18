import http from '@ohos.net.http';
import { cookieManager } from './CookieManager';

export class HttpClient {
  private static baseUrl: string = "https://bbs.binmt.cc/";
  private static userAgent: string = "Mozilla/5.0 (Linux; Android 10; HarmonyOS) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36";

  static async request(method: http.RequestMethod, url: string, body?: Record<string, string>, extraHeaders?: Record<string, string>): Promise<string> {
    let httpRequest = http.createHttp();
    let fullUrl = url.startsWith('http') ? url : `${HttpClient.baseUrl}${url}`;
    
    let headers: Record<string, string> = {
      'User-Agent': HttpClient.userAgent,
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9',
      'Referer': 'https://bbs.binmt.cc/'
    };

    let cookie = cookieManager.get();
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
      let formData: string[] = [];
      // ArkTS 禁止 for...in，使用 Object.keys
      Object.keys(body).forEach((key: string) => {
        formData.push(`${encodeURIComponent(key)}=${encodeURIComponent(body[key])}`);
      });
      options.extraData = formData.join('&');
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }

    try {
      let response = await httpRequest.request(fullUrl, options);
      
      let setCookie = response.header['set-cookie'];
      if (setCookie) {
        let newCookieStr = typeof setCookie === 'string' ? setCookie : (setCookie as string[]).join('; ');
        let currentCookie = cookieManager.get();
        if (!currentCookie) {
          await cookieManager.save(newCookieStr);
        } else {
          await cookieManager.save(currentCookie + '; ' + newCookieStr);
        }
      }
      return response.result as string;
    } catch (error) {
      // ArkTS 禁止 throw 任意类型，必须 throw Error
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

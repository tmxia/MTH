import http from '@ohos.net.http';
import { cookieManager } from './CookieManager';

export class HttpClient {
  public static baseUrl: string = "https://bbs.binmt.cc/";
  private static userAgent: string = "Mozilla/5.0 (Linux; Android 10; HarmonyOS) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36";

  static async request(method: http.RequestMethod, url: string, body?: string | Record<string, string>, extraHeaders?: Record<string, string>): Promise<string> {
    let httpRequest = http.createHttp();
    let fullUrl = url.startsWith('http') ? url : HttpClient.baseUrl + url;
    
    let headers: Record<string, string> = {
      'User-Agent': HttpClient.userAgent,
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Referer': 'https://bbs.binmt.cc/forum.php'
    };

    let cookie = cookieManager.get();
    if (cookie) {
      headers['Cookie'] = cookie;
    }

    if (extraHeaders) {
      let keys: string[] = Object.keys(extraHeaders);
      for (let i = 0; i < keys.length; i++) {
        let k: string = keys[i];
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
      let bodyKeys: string[] = Object.keys(body);
      for (let i = 0; i < bodyKeys.length; i++) {
        let k: string = bodyKeys[i];
        let val: string = body[k] as string; // 强制断言为 string
        formData.push(encodeURIComponent(k) + '=' + encodeURIComponent(val));
      }
      options.extraData = formData.join('&');
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }

    try {
      let response: http.HttpResponse = await httpRequest.request(fullUrl, options);
      
      // 强制将 header 断言为明确的 Record 类型，杜绝 any
      let responseHeaders = response.header as Record<string, string | string[]>;
      let setCookie = responseHeaders['set-cookie'];
      
      if (setCookie) {
        let newCookieStr: string = '';
        if (typeof setCookie === 'string') {
          newCookieStr = setCookie as string;
        } else if (Array.isArray(setCookie)) {
          newCookieStr = (setCookie as string[]).join('; ');
        }
        let currentCookie: string = cookieManager.get();
        if (!currentCookie) {
          await cookieManager.save(newCookieStr);
        } else {
          await cookieManager.save(currentCookie + '; ' + newCookieStr);
        }
      }
      return response.result as string;
    } catch (error) {
      // ArkTS 对 catch 变量极度严格，必须显式转换
      let err = error as Error;
      let errMsg: string = err.message ? err.message : 'Unknown Error';
      throw new Error('Http Request Failed: ' + errMsg);
    } finally {
      httpRequest.destroy();
    }
  }

  static get(url: string, headers?: Record<string, string>): Promise<string> {
    return HttpClient.request(http.RequestMethod.GET, url, undefined, headers);
  }

  static post(url: string, body: string | Record<string, string>, headers?: Record<string, string>): Promise<string> {
    return HttpClient.request(http.RequestMethod.POST, url, body, headers);
  }
}

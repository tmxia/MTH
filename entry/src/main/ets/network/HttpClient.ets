import request from '@ohos.request';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import http from '@ohos.net.http';
import { cookieManager } from './CookieManager';
import { WafSolver } from './WafSolver';
import { LogStore, LogLevel } from '../common/LogStore';

export class HttpClient {
  public static baseUrl: string = "https://bbs.binmt.cc/";
  private static userAgent: string = "Mozilla/5.0 (Linux; Android 10; HarmonyOS) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36";

  static async request(method: http.RequestMethod, url: string, body?: string | object, extraHeaders?: Record<string, string>, _wafRetry: boolean = false): Promise<string> {
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
      let text = response.result as string;
      if (!_wafRetry && WafSolver.looksLikeChallenge(text)) {
        LogStore.add(LogLevel.WARN, 'WAF', '检测到 WAF 挑战: ' + url);
        let wafVal = WafSolver.solve(text);
        if (wafVal) {
          let existingCookie = cookieManager.get();
          // 去除已有 acw_sc__v2，避免重复累积
          let cleanCookie = '';
          if (existingCookie) {
            let parts: string[] = existingCookie.split(';');
            let kept: string[] = [];
            for (let pi = 0; pi < parts.length; pi++) {
              let one: string = parts[pi].trim();
              if (one && one.indexOf('acw_sc__v2=') !== 0) {
                kept.push(one);
              }
            }
            cleanCookie = kept.join('; ');
          }
          let newCookie = cleanCookie
            ? cleanCookie + '; acw_sc__v2=' + wafVal
            : 'acw_sc__v2=' + wafVal;
          await cookieManager.save(newCookie);
          return HttpClient.request(method, url, body, extraHeaders, true);
        }
      }
      const code = response.responseCode;
      LogStore.add(LogLevel.INFO, 'HTTP', (method === http.RequestMethod.POST ? 'POST ' : 'GET ') + url, 'status=' + code + ' len=' + text.length);
      return text;
    } catch (error) {
      // ArkTS 对 catch 变量极度严格，必须显式转换
      let err = error as Error;
      let errMsg: string = err.message ? err.message : 'Unknown Error';
      LogStore.add(LogLevel.ERROR, 'HTTP', '请求失败: ' + url, errMsg);
      throw new Error('Http Request Failed: ' + errMsg);
    } finally {
      httpRequest.destroy();
    }
  }

  static get(url: string, headers?: Record<string, string>): Promise<string> {
    return HttpClient.request(http.RequestMethod.GET, url, undefined, headers);
  }

  static post(url: string, body: string | object, headers?: Record<string, string>): Promise<string> {
    return HttpClient.request(http.RequestMethod.POST, url, body, headers);
  }

  static async uploadFile(url: string, filePath: string, formData: Record<string, string>): Promise<string> {
    const uploadConfig: request.UploadConfig = {
      url: HttpClient.baseUrl + url,
      header: {
        'User-Agent': HttpClient.userAgent,
        'Cookie': cookieManager.get(),
        'Referer': 'https://bbs.binmt.cc/forum.php'
      },
      method: 'POST',
      files: [{
        filename: 'image.jpg',
        name: 'Filedata',
        uri: filePath,
        type: 'jpg'
      }],
      data: []
    };
    
    // 把 formData 转成 request.RequestData 数组
    const keys = Object.keys(formData);
    for (let i = 0; i < keys.length; i++) {
      uploadConfig.data.push({ name: keys[i], value: formData[keys[i]] });
    }

    try {
      let uploadTask = await request.uploadFile(getContext(), uploadConfig);
      return new Promise<string>((resolve, reject) => {
        uploadTask.on('complete', (taskStates: Array<request.TaskState>) => {
          // 读取上传后的服务器响应比较麻烦，通常这里需要发个回调
          // 由于鸿蒙 API 限制，这里为了简化，如果上传成功返回 true
          resolve("UPLOAD_SUCCESS");
        });
      });
    } catch (err) {
      throw new Error('Upload Failed: ' + JSON.stringify(err));
    }
  }

  static async downloadImage(url: string): Promise<ArrayBuffer> {
    let httpRequest = http.createHttp();
    let fullUrl = url.startsWith('http') ? url : HttpClient.baseUrl + url;
    
    let headers: Record<string, string> = {
      'User-Agent': HttpClient.userAgent,
      'Referer': 'https://bbs.binmt.cc/forum.php',
      'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8'
    };
    
    let cookie = cookieManager.get();
    if (cookie) headers['Cookie'] = cookie;

    let options: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      header: headers,
      expectDataType: http.HttpDataType.ARRAY_BUFFER,
      readTimeout: 15000,
      connectTimeout: 15000
    };

    try {
      let response = await httpRequest.request(fullUrl, options);
      return response.result as ArrayBuffer;
    } catch (error) {
      throw new Error('Download Image Failed');
    } finally {
      httpRequest.destroy();
    }
  }

  // ===== 手动 multipart 上传（拿响应体） =====
  static async uploadMultipart(
    url: string,
    filePath: string,
    fileFieldName: string,
    fileName: string,
    fileMime: string,
    formData: Record<string, string>
  ): Promise<string> {
    const BOUNDARY = '----MTFBoundary' + Date.now();
    const enc = new util.TextEncoder();
    const chunks: Uint8Array[] = [];

    const keys = Object.keys(formData);
    for (let i = 0; i < keys.length; i++) {
      const k = keys[i];
      const v = formData[k];
      const part = '--' + BOUNDARY + '\r\n' +
        'Content-Disposition: form-data; name="' + k + '"\r\n\r\n' +
        v + '\r\n';
      chunks.push(enc.encodeInto(part));
    }

    const fileHeader = '--' + BOUNDARY + '\r\n' +
      'Content-Disposition: form-data; name="' + fileFieldName + '"; filename="' + fileName + '"\r\n' +
      'Content-Type: ' + fileMime + '\r\n\r\n';
    chunks.push(enc.encodeInto(fileHeader));

    const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
    try {
      const stat = await fs.stat(filePath);
      const fileBuf = new ArrayBuffer(stat.size);
      await fs.read(file.fd, fileBuf);
      chunks.push(new Uint8Array(fileBuf));
    } finally {
      await fs.close(file);
    }

    const footer = '\r\n--' + BOUNDARY + '--\r\n';
    chunks.push(enc.encodeInto(footer));

    let total = 0;
    for (let i = 0; i < chunks.length; i++) total += chunks[i].length;
    const merged = new Uint8Array(total);
    let off = 0;
    for (let i = 0; i < chunks.length; i++) {
      merged.set(chunks[i], off);
      off += chunks[i].length;
    }

    const httpRequest = http.createHttp();
    const headers: Record<string, string> = {
      'User-Agent': HttpClient.userAgent,
      'Content-Type': 'multipart/form-data; boundary=' + BOUNDARY,
      'Referer': 'https://bbs.binmt.cc/forum.php'
    };
    const cookie = cookieManager.get();
    if (cookie) headers['Cookie'] = cookie;

    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: headers,
      extraData: merged.buffer as ArrayBuffer,
      expectDataType: http.HttpDataType.STRING,
      readTimeout: 30000,
      connectTimeout: 30000
    };

    try {
      const response = await httpRequest.request(fullUrlOf(url), options);
      return response.result as string;
    } finally {
      httpRequest.destroy();
    }
  }

}



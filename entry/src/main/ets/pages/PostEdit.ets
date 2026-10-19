import { forumRepository } from '../repo/ForumRepository';
import { NewThreadPageData, ImageUpload } from '../models/Models';
import { DraftStore, DraftData } from '../common/DraftStore';
import { MtfColors } from '../common/Theme';
import { SmileyPanel } from '../common/SmileyPanel';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct PostEdit {
  @State fid: string = '';
  @State forumName: string = '';
  @State initData: NewThreadPageData | null = null;
  @State title: string = '';
  @State content: string = '';
  @State isUploading: boolean = false;
  @State isSubmitting: boolean = false;
  @State showSmiley: boolean = false;
  @State isEditMode: boolean = false;
  @State editTid: string = '';
  @State editPid: string = '';

  onPageShow() {
    const picked = AppStorage.Get<string>('pickedAtUser');
    if (picked && picked.length > 0) {
      this.content = this.content + ' @' + picked + ' ';
      AppStorage.SetOrCreate('pickedAtUser', '');
      if (this.fid) {
        DraftStore.saveDraft(this.fid, this.title, this.content);
      }
    }
  }

  async aboutToAppear() {
    // 先判断编辑模式
    const params = router.getParams() as Record<string, string>;
    if (params && params.tid && params.pid) {
      this.isEditMode = true;
      this.editTid = params.tid;
      this.editPid = params.pid;
      this.fid = params.fid || '';
      this.forumName = params.forumName || '编辑帖子';
      // 先用路由参数作为兜底
      this.title = params.subject || '';
      this.content = params.message || '';
      // 后台拉取真实原始内容（更准确）
      try {
        const init = await forumRepository.fetchEditPostInit(params.tid, params.pid);
        if (init) {
          this.initData = init as NewThreadPageData;
          if (init.subject) this.title = init.subject;
          if (init.message) this.content = init.message;
          if (init.permissionDenied) {
            promptAction.showToast({ message: init.permissionDenied });
          }
        }
      } catch (e) {}
      return;
    }
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    await DraftStore.init(context);

    const params = router.getParams() as Record<string, string>;
    if (params && params.fid) {
      this.fid = params.fid;
      this.forumName = params.name || '未知版块';
      await this.loadInitData();
      
      // 恢复草稿
      const draft: DraftData | null = await DraftStore.getDraft(this.fid);
      if (draft) {
        this.title = draft.title;
        this.content = draft.content;
        promptAction.showToast({ message: '已恢复上次未提交的草稿' });
      }
    } else {
      promptAction.showToast({ message: '缺少版块参数' });
    }
  }

  onPageHide() {
    // 页面隐藏时自动保存草稿
    if (this.title || this.content) {
      DraftStore.saveDraft(this.fid, this.title, this.content);
    }
  }

  async loadInitData() {
    try {
      this.initData = await forumRepository.fetchNewThreadInit(this.fid);
    } catch (e) {
      promptAction.showToast({ message: '获取发帖令牌失败' });
    }
  }

  async selectImage() {
    if (!this.initData || !this.initData.uploadHash) {
      promptAction.showToast({ message: '未获取到上传凭证' });
      return;
    }
    try {
      let photoPicker = new photoAccessHelper.PhotoViewPicker();
      let res = await photoPicker.select({ maxSelectNumber: 1, MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE }) as photoAccessHelper.PhotoSelectResult;
      if (res.photoUris.length > 0) {
        this.isUploading = true;
        let img = await forumRepository.uploadImage(res.photoUris[0], this.initData.uploadUid || '', this.initData.uploadHash);
        if (img && img.aid) {
          this.content += `\n[attach]${img.aid}[/attach]\n`;
          promptAction.showToast({ message: '图片已插入' });
        } else {
          promptAction.showToast({ message: '图片上传失败' });
        }
        this.isUploading = false;
      }
    } catch (e) {
      console.error(JSON.stringify(e));
      this.isUploading = false;
    }
  }

  async submitPost() {
    if (!this.title || !this.content) {
      promptAction.showToast({ message: '标题和内容不能为空' });
      return;
    }
    // 编辑模式分支（必须在 initData 检查之前，因为编辑模式不加载 initData）
    if (this.isEditMode) {
      this.isSubmitting = true;
      try {
        let fh = '';
        if (this.initData) {
          fh = this.initData.formhash || '';
        }
        if (!fh) {
          fh = await forumRepository.fetchFormhash();
        }
        const eres = await forumRepository.editPost(this.editTid, this.editPid, fh, this.content, this.title);
        if (eres && eres.success) {
          promptAction.showToast({ message: '编辑成功' });
          router.back();
        } else {
          promptAction.showToast({ message: (eres && eres.message) || '编辑失败' });
        }
      } catch (e) {
        promptAction.showToast({ message: '编辑失败：' + (e as Error).message });
      } finally {
        this.isSubmitting = false;
      }
      return;
    }

    if (!this.initData) return;

    this.isSubmitting = true;
    try {
      let res = await forumRepository.newThread(
        this.fid, this.initData.formhash, this.initData.posttime || '', this.title, this.content
      );
      if (res.success) {
        promptAction.showToast({ message: '发布成功' });
        await DraftStore.clearDraft(this.fid); // 发布成功清空草稿
        router.back();
      } else {
        promptAction.showToast({ message: res.message || '发布失败' });
      }
    } catch (e) {
      promptAction.showToast({ message: '网络异常' });
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Text('< 取消').fontSize(16).fontColor(MtfColors.textMain).onClick(() => router.back())
        Text(`发帖至: ${this.forumName}`).fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Button('发布')
          .height(32).backgroundColor(MtfColors.primary).fontSize(14).fontColor('#FFFFFF')
          .enabled(!this.isSubmitting && !this.isUploading)
          .onClick(() => this.submitPost())
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor(MtfColors.bgWhite)

      Column({ space: 15 }) {
        TextInput({ placeholder: '请输入标题', text: this.title })
          .height(50).backgroundColor(MtfColors.bgLight).borderRadius(8)
          .onChange((val: string) => {
            this.title = val;
            DraftStore.saveDraft(this.fid, this.title, this.content); // 实时保存草稿
          })

        Row() {
          Blank()
          Text('@ 插入用户').fontSize(13).fontColor('#4D6BFE')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(12)
            .backgroundColor('#E8EEFF')
            .onClick(() => router.pushUrl({ url: 'pages/AtUserPicker' }))
        }.width('100%').margin({ bottom: 4 })

        TextArea({ placeholder: '请输入正文内容...', text: this.content })
          .height(300).backgroundColor(MtfColors.bgLight).borderRadius(8)
          .onChange((val: string) => {
            this.content = val;
            DraftStore.saveDraft(this.fid, this.title, this.content);
          })

        Row({ space: 10 }) {
          Button(this.isUploading ? '上传中...' : '插入图片')
            .backgroundColor(MtfColors.primaryLight).fontColor(MtfColors.primary)
            .enabled(!this.isUploading)
            .onClick(() => this.selectImage())
            
          Button('插入表情')
            .backgroundColor(MtfColors.bgLight).fontColor(MtfColors.textMainColor)
            .onClick(() => { this.showSmiley = !this.showSmiley; })
        }.width('100%')
        
        if (this.showSmiley) {
          SmileyPanel({
            onSelect: (code: string) => {
              this.content += code;
            }
          })
        }
      }
      .width('100%').padding(15)
    }.width('100%').height('100%').backgroundColor(MtfColors.bgWhite)
  }
}

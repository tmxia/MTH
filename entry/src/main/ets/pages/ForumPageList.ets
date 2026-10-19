import { forumRepository, ForumSort } from '../repo/ForumRepository';
import { ForumPage, Thread } from '../models/Models';
import { NetImage } from '../common/NetImage';
import { MtfColors } from '../common/Theme';
import { SkeletonThreadCard } from '../common/SkeletonCard';
import router from '@ohos.router';

@Entry
@Component
struct ForumPageList {
  @State fp: ForumPage | null = null;
  @State isLoading: boolean = false;
  @State isLoadingMore: boolean = false;
  @State errorMsg: string = '';
  @State fid: string = '';
  @State title: string = '';
  @State page: number = 1;
  @State hasNext: boolean = true;
  @State threads: Array<Thread> = [];
  @State announcements: Array<Thread> = [];
  
  @State currentSort: ForumSort = ForumSort.LATEST;
  private sorts: Array<ForumSort> = [ForumSort.LATEST, ForumSort.HOT, ForumSort.DIGEST];

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params.fid) {
      this.fid = params.fid;
      this.title = params.name || '版块列表';
      await this.refreshData();
    } else {
      this.errorMsg = "未找到版块ID";
    }
  }

  async refreshData() {
    if (this.isLoading) return;
    this.isLoading = true;
    this.page = 1;
    this.hasNext = true;
    try {
      const data = await forumRepository.forumPage(this.fid, this.page, this.currentSort);
      this.announcements = data.announcements;
      this.threads = data.threads;
      this.hasNext = data.hasNext;
    } catch (e) {
      this.errorMsg = (e as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  async loadMore() {
    if (!this.hasNext || this.isLoadingMore) return;
    this.isLoadingMore = true;
    this.page++;
    try {
      const data = await forumRepository.forumPage(this.fid, this.page, this.currentSort);
      this.threads = this.threads.concat(data.threads);
      this.hasNext = data.hasNext;
    } catch (e) {
      console.error(JSON.stringify(e));
    } finally {
      this.isLoadingMore = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor(MtfColors.textMainColor).onClick(() => router.back())
        Text(this.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor(MtfColors.textMainColor).layoutWeight(1).textAlign(TextAlign.Center)
        Text('发帖').fontSize(14).fontColor('#FFFFFF').backgroundColor(MtfColors.primary).padding({ left: 10, right: 10, top: 4, bottom: 4 }).borderRadius(4)
          .onClick(() => router.pushUrl({ url: 'pages/PostEdit', params: { fid: this.fid, name: this.title } }))
      }.width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor(MtfColors.bgWhiteColor)

      // 排序 Tab 栏
      Row() {
        ForEach(this.sorts, (sort: ForumSort) => {
          Text(sort)
            .fontSize(15)
            .fontWeight(this.currentSort === sort ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentSort === sort ? MtfColors.primary : MtfColors.textSubColor)
            .margin({ right: 20 })
            .onClick(() => {
              if (this.currentSort !== sort) {
                this.currentSort = sort;
                this.refreshData();
              }
            })
        }, (sort: ForumSort) => sort)
      }.width('100%').padding({ left: 16, top: 10, bottom: 10 }).backgroundColor(MtfColors.bgWhiteColor)

      if (this.isLoading && this.threads.length === 0) {
        List({ space: 10 }) {
          ForEach([1, 2, 3, 4, 5], (item: number) => {
            ListItem() { SkeletonThreadCard() }
          }, (item: number) => item.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding(10)
        .backgroundColor(MtfColors.bgLightColor)
      } else if (this.errorMsg !== '') {
        Text(this.errorMsg).fontSize(16).fontColor(Color.Red).margin({ top: 100 })
      } else {
        Refresh({ refreshing: $$this.isLoading }) {
          List({ space: 10 }) {
            if (this.currentSort === ForumSort.LATEST && this.announcements.length > 0) {
              ListItem() {
                Text('版块公告').fontSize(14).fontWeight(FontWeight.Bold).fontColor(MtfColors.danger).padding({ left: 10, top: 10, bottom: 5 })
              }
            }
            ForEach(this.announcements, (item: Thread) => {
              ListItem() { this.ThreadCard(item, true) }
            }, (item: Thread) => item.tid)

            ForEach(this.threads, (item: Thread) => {
              ListItem() { this.ThreadCard(item, false) }
              .onClick(() => router.pushUrl({ url: 'pages/ThreadDetail', params: { tid: item.tid } }))
            }, (item: Thread) => item.tid)

            if (this.isLoadingMore) {
              ListItem() { Row() { LoadingProgress().width(24).height(24) }.width('100%').justifyContent(FlexAlign.Center).padding(10) }
            } else if (!this.hasNext && this.threads.length > 0) {
              ListItem() { Text('没有更多了').fontSize(12).fontColor(MtfColors.textLight).width('100%').textAlign(TextAlign.Center).padding(15) }
            }
          }
          .width('100%').layoutWeight(1).padding(10).backgroundColor(MtfColors.bgLightColor)
          .onReachEnd(() => this.loadMore())
        }
        .onRefreshing(() => this.refreshData())
        .width('100%').layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor(MtfColors.bgLightColor)
  }

  @Builder
  ThreadCard(thread: Thread, isAnnouncement: boolean) {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Image(thread.avatarUrl ? thread.avatarUrl : $r('app.media.icon')).width(30).height(30).borderRadius(15).backgroundColor(MtfColors.dividerColor)
        Column() {
          Text(thread.authorName || '匿名用户').fontSize(14).fontWeight(FontWeight.Medium).fontColor(MtfColors.textMainColor)
          Text(thread.timeText || '刚刚').fontSize(11).fontColor(MtfColors.textLight)
        }.alignItems(HorizontalAlign.Start)
        Blank()
        if (isAnnouncement) {
          Text('公告').fontSize(10).fontColor('#FFFFFF').backgroundColor(MtfColors.danger).padding({ left: 4, right: 4, top: 1, bottom: 1 }).borderRadius(4)
        }
      }.width('100%')

      Text(thread.subject).fontSize(16).fontWeight(FontWeight.Bold).fontColor(MtfColors.textMainColor).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })

      if (thread.imageUrls && thread.imageUrls.length > 0) {
        NetImage({ src: thread.imageUrls[0], imgWidth: '100%', imgHeight: 120, imgRadius: 6 })
      }

      Row({ space: 15 }) {
        Text(`阅读 ${thread.viewCount || 0}`).fontSize(12).fontColor(MtfColors.textLight)
        Text(`回复 ${thread.replyCount || 0}`).fontSize(12).fontColor(MtfColors.textLight)
        Blank()
      }.width('100%').margin({ top: 4 })
    }
    .width('100%').padding(12).backgroundColor(MtfColors.bgWhiteColor).borderRadius(10)
  }
}

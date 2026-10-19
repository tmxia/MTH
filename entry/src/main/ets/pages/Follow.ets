import router from '@ohos.router';
import { forumRepository } from '../repo/ForumRepository';
import { FollowUserItem } from '../models/Models';

@Entry
@Component
struct Follow {
  @State currentTab: number = 0;
  @State loading: boolean = true;
  @State following: FollowUserItem[] = [];
  @State followers: FollowUserItem[] = [];
  @State followingPage: number = 1;
  @State followersPage: number = 1;
  @State followingHasNext: boolean = false;
  @State followersHasNext: boolean = false;
  @State loadingMore: boolean = false;

  async aboutToAppear() {
    await this.loadAll();
  }

  async loadAll() {
    this.loading = true;
    try {
      const fg = await forumRepository.followList('following', 1);
      this.following = (fg.users as FollowUserItem[]) || [];
      this.followingPage = 1;
      this.followingHasNext = fg.hasNext === true;
      const fr = await forumRepository.followList('follower', 1);
      this.followers = (fr.users as FollowUserItem[]) || [];
      this.followersPage = 1;
      this.followersHasNext = fr.hasNext === true;
    } catch (e) {
      // 静默
    } finally {
      this.loading = false;
    }
  }

  async loadMore() {
    if (this.loadingMore) return;
    this.loadingMore = true;
    try {
      if (this.currentTab === 0 && this.followingHasNext) {
        const next = await forumRepository.followList('following', this.followingPage + 1);
        for (const u of (next.users as FollowUserItem[]) || []) {
          this.following.push(u);
        }
        this.followingPage++;
        this.followingHasNext = next.hasNext === true;
      } else if (this.currentTab === 1 && this.followersHasNext) {
        const next = await forumRepository.followList('follower', this.followersPage + 1);
        for (const u of (next.users as FollowUserItem[]) || []) {
          this.followers.push(u);
        }
        this.followersPage++;
        this.followersHasNext = next.hasNext === true;
      }
    } catch (e) {
    } finally {
      this.loadingMore = false;
    }
  }

  getMutual(): FollowUserItem[] {
    const ids: string[] = [];
    for (const u of this.following) {
      if (u.uid) ids.push(u.uid);
    }
    const out: FollowUserItem[] = [];
    for (const u of this.followers) {
      if (u.uid && ids.indexOf(u.uid) >= 0) {
        out.push(u);
      }
    }
    return out;
  }

  getCurrentList(): FollowUserItem[] {
    if (this.currentTab === 0) return this.following;
    if (this.currentTab === 1) return this.followers;
    return this.getMutual();
  }

  async toggleFollow(user: FollowUserItem, isFollowingNow: boolean) {
    const wantFollow = !isFollowingNow;
    const ok = await forumRepository.toggleFollowUser(user.uid || '', wantFollow);
    if (ok) {
      // 本地更新状态
      for (let i = 0; i < this.following.length; i++) {
        if (this.following[i].uid === user.uid) {
          this.following[i].isFollowing = wantFollow;
        }
      }
      for (let i = 0; i < this.followers.length; i++) {
        if (this.followers[i].uid === user.uid) {
          this.followers[i].isFollowing = wantFollow;
        }
      }
      // 如果取消关注了，从 following 里删掉
      if (!wantFollow) {
        const kept: FollowUserItem[] = [];
        for (const u of this.following) {
          if (u.uid !== user.uid) kept.push(u);
        }
        this.following = kept;
      }
    } else {
      AlertDialog.show({
        title: '操作失败',
        message: '请稍后重试，或检查登录状态',
        primaryButton: {
          value: '知道了',
          action: () => {}
        }
      });
    }
  }

  openProfile(user: FollowUserItem) {
    if (user.uid) {
      router.pushUrl({ url: 'pages/UserProfilePage', params: { uid: user.uid } });
    }
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Text('关注与粉丝')
          .fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }
      .width('100%').height(50)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Row() {
        Column() {
          Text('关注 (' + this.following.length + ')')
            .fontSize(14)
            .fontColor(this.currentTab === 0 ? '#4D6BFE' : '#666')
            .fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Normal)
            .padding({ top: 8, bottom: 8 })
        }
        .layoutWeight(1)
        .onClick(() => { this.currentTab = 0; })

        Column() {
          Text('粉丝 (' + this.followers.length + ')')
            .fontSize(14)
            .fontColor(this.currentTab === 1 ? '#4D6BFE' : '#666')
            .fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Normal)
            .padding({ top: 8, bottom: 8 })
        }
        .layoutWeight(1)
        .onClick(() => { this.currentTab = 1; })

        Column() {
          Text('互关 (' + this.getMutual().length + ')')
            .fontSize(14)
            .fontColor(this.currentTab === 2 ? '#4D6BFE' : '#666')
            .fontWeight(this.currentTab === 2 ? FontWeight.Bold : FontWeight.Normal)
            .padding({ top: 8, bottom: 8 })
        }
        .layoutWeight(1)
        .onClick(() => { this.currentTab = 2; })
      }
      .width('100%').backgroundColor('#FFFFFF')
      .padding({ top: 6, bottom: 6 })

      if (this.loading) {
        Column() { LoadingProgress().width(50).height(50).color('#4D6BFE') }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.getCurrentList().length === 0) {
        Column() {
          Text('暂无数据').fontSize(14).fontColor('#999')
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 1 }) {
          ForEach(this.getCurrentList(), (item: FollowUserItem) => {
            ListItem() {
              Row() {
                if (item.avatarUrl) {
                  Image(item.avatarUrl).width(44).height(44).borderRadius(22).margin({ right: 10 })
                } else {
                  Column() {
                    Text(item.username ? item.username.substring(0, 1) : '?')
                      .fontSize(16).fontColor('#FFFFFF')
                  }
                  .width(44).height(44).borderRadius(22).backgroundColor('#4D6BFE')
                  .justifyContent(FlexAlign.Center).margin({ right: 10 })
                }
                Column({ space: 3 }) {
                  Text(item.username || ('用户 ' + item.uid)).fontSize(15).fontColor('#333').maxLines(1)
                  if (item.fansCount) {
                    Text('粉丝 ' + item.fansCount + ' · 关注 ' + (item.followCount || '0'))
                      .fontSize(11).fontColor('#999')
                  }
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                  .onClick(() => this.openProfile(item))

                Text(item.isFollowing ? '已关注' : '关注')
                  .fontSize(13).fontColor(item.isFollowing ? '#999' : '#4D6BFE')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .borderRadius(14)
                  .borderWidth(1)
                  .borderColor(item.isFollowing ? '#DDDDDD' : '#4D6BFE')
                  .onClick(() => this.toggleFollow(item, item.isFollowing === true))
              }
              .width('100%').padding(12).backgroundColor('#FFFFFF')
              .alignItems(VerticalAlign.Center)
            }
          }, (item: FollowUserItem) => (item.uid || '') + '_' + this.currentTab)
          if ((this.currentTab === 0 && this.followingHasNext) ||
              (this.currentTab === 1 && this.followersHasNext)) {
            ListItem() {
              Text(this.loadingMore ? '加载中…' : '加载更多')
                .fontSize(13).fontColor('#4D6BFE')
                .padding(12).width('100%').textAlign(TextAlign.Center)
                .onClick(() => this.loadMore())
            }
          }
        }
        .width('100%').layoutWeight(1).backgroundColor('#F5F5F5')
      }
    }
    .width('100%').height('100%')
  }

  // 移除 @Builder，改用内联渲染
}

import router from '@ohos.router';
import { forumRepository } from '../repo/ForumRepository';
import { AtUser } from '../models/Models';

@Entry
@Component
struct AtUserPicker {
  @State keyword: string = '';
  @State loading: boolean = true;
  @State friends: AtUser[] = [];
  @State follows: AtUser[] = [];
  @State results: AtUser[] = [];
  @State searching: boolean = false;
  private searchTimer: number = -1;

  async aboutToAppear() {
    this.loadLists();
  }

  async loadLists() {
    this.loading = true;
    try {
      const f = await forumRepository.fetchFriends();
      this.friends = f || [];
      const fl = await forumRepository.fetchFollows();
      this.follows = fl || [];
    } catch (e) {
      // 静默
    } finally {
      this.loading = false;
    }
  }

  onKeywordChange(v: string) {
    this.keyword = v;
    if (this.searchTimer > 0) {
      clearTimeout(this.searchTimer);
    }
    this.searchTimer = setTimeout(() => {
      this.doSearch(v);
    }, 300);
  }

  async doSearch(kw: string) {
    const t = kw.trim();
    if (!t) {
      this.results = [];
      this.searching = false;
      return;
    }
    this.searching = true;
    try {
      const r = await forumRepository.searchUsers(t);
      this.results = r || [];
    } catch (e) {
      this.results = [];
    } finally {
      this.searching = false;
    }
  }

  pick(u: AtUser) {
    // 通过 AppStorage 回传给上一页，上一页 onPageShow 里读
    AppStorage.SetOrCreate('pickedAtUser', u.name);
    router.back();
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Row() {
          TextInput({ placeholder: '@ 用户名搜索', text: this.keyword })
            .fontSize(14)
            .backgroundColor('#F2F2F2')
            .borderRadius(18)
            .height(36)
            .layoutWeight(1)
            .onChange((v: string) => this.onKeywordChange(v))
        }
        .layoutWeight(1).margin({ left: 8, right: 8 })
        Blank().width(20)
      }
      .width('100%').height(50)
      .padding({ left: 16, right: 12 })
      .backgroundColor('#FFFFFF')

      if (this.keyword.trim().length > 0) {
        if (this.searching) {
          Column() { LoadingProgress().width(40).height(40).color('#4D6BFE') }
            .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else if (this.results.length === 0) {
          Column() { Text('未找到匹配的用户').fontSize(14).fontColor('#999') }
            .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          List({ space: 1 }) {
            ForEach(this.results, (u: AtUser) => {
              ListItem() { this.userRow(u) }
            }, (u: AtUser) => 'r_' + u.uid)
          }.width('100%').layoutWeight(1).backgroundColor('#F5F5F5')
        }
      } else {
        if (this.loading) {
          Column() { LoadingProgress().width(40).height(40).color('#4D6BFE') }
            .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else if (this.friends.length === 0 && this.follows.length === 0) {
          Column() {
            Text('暂无好友或关注用户').fontSize(14).fontColor('#999')
            Text('在上方搜索框输入用户名').fontSize(12).fontColor('#BBB').margin({ top: 6 })
          }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          List({ space: 1 }) {
            if (this.friends.length > 0) {
              ListItem() {
                Text('好友 (' + this.friends.length + ')')
                  .fontSize(12).fontColor('#999')
                  .padding({ left: 16, top: 10, bottom: 6 })
                  .backgroundColor('#F5F5F5').width('100%')
              }
              ForEach(this.friends, (u: AtUser) => {
                ListItem() { this.userRow(u) }
              }, (u: AtUser) => 'f_' + u.uid)
            }
            if (this.follows.length > 0) {
              ListItem() {
                Text('关注 (' + this.follows.length + ')')
                  .fontSize(12).fontColor('#999')
                  .padding({ left: 16, top: 10, bottom: 6 })
                  .backgroundColor('#F5F5F5').width('100%')
              }
              ForEach(this.follows, (u: AtUser) => {
                ListItem() { this.userRow(u) }
              }, (u: AtUser) => 'fl_' + u.uid)
            }
          }.width('100%').layoutWeight(1).backgroundColor('#F5F5F5')
        }
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  userRow(u: AtUser) {
    Row() {
      if (u.avatarUrl) {
        Image(u.avatarUrl).width(40).height(40).borderRadius(20).margin({ right: 10 })
      } else {
        Column() {
          Text(u.name ? u.name.substring(0, 1) : '?').fontSize(16).fontColor('#FFFFFF')
        }
        .width(40).height(40).borderRadius(20).backgroundColor('#4D6BFE')
        .justifyContent(FlexAlign.Center).margin({ right: 10 })
      }
      Column({ space: 4 }) {
        Text(u.name).fontSize(15).fontColor('#333').maxLines(1)
        if (u.subtitle) {
          Text(u.subtitle).fontSize(11).fontColor('#999').maxLines(1)
        }
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      Text('@').fontSize(16).fontColor('#4D6BFE')
    }
    .width('100%').padding(12).backgroundColor('#FFFFFF')
    .onClick(() => this.pick(u))
  }
}

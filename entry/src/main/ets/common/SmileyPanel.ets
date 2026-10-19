import { MtfColors } from './Theme';
import { forumRepository } from '../repo/ForumRepository';
import { Smiley, SmileyPack } from '../models/Models';

// 降级用的硬编码 emoji（网络失败时显示）
interface FallbackItem {
  code: string;
  emoji: string;
}

const FALLBACK_ITEMS: FallbackItem[] = [
  { code: '[微笑]', emoji: '😊' }, { code: '[撇嘴]', emoji: '😒' },
  { code: '[色]', emoji: '😍' }, { code: '[发呆]', emoji: '😳' },
  { code: '[得意]', emoji: '😎' }, { code: '[流泪]', emoji: '😭' },
  { code: '[害羞]', emoji: '😳' }, { code: '[闭嘴]', emoji: '🤐' },
  { code: '[睡]', emoji: '😴' }, { code: '[大哭]', emoji: '😭' },
  { code: '[尴尬]', emoji: '😅' }, { code: '[发怒]', emoji: '😡' },
  { code: '[调皮]', emoji: '😜' }, { code: '[呲牙]', emoji: '😁' },
  { code: '[惊讶]', emoji: '😱' }, { code: '[难过]', emoji: '🙁' },
  { code: '[酷]', emoji: '😎' }, { code: '[冷汗]', emoji: '😓' },
  { code: '[抓狂]', emoji: '😫' }, { code: '[吐]', emoji: '🤮' },
  { code: '[偷笑]', emoji: '🤭' }, { code: '[可爱]', emoji: '🥰' },
  { code: '[白眼]', emoji: '🙄' }, { code: '[傲慢]', emoji: '😤' },
  { code: '[饥饿]', emoji: '🤤' }, { code: '[困]', emoji: '😪' },
  { code: '[惊恐]', emoji: '😨' }, { code: '[流汗]', emoji: '😰' },
  { code: '[憨笑]', emoji: '😄' }, { code: '[奋斗]', emoji: '💪' },
  { code: '[疑问]', emoji: '❓' }, { code: '[嘘]', emoji: '🤫' },
  { code: '[晕]', emoji: '😵' }, { code: '[衰]', emoji: '😩' },
  { code: '[骷髅]', emoji: '💀' }, { code: '[敲打]', emoji: '🔨' },
  { code: '[再见]', emoji: '👋' }, { code: '[擦汗]', emoji: '😅' },
  { code: '[鼓掌]', emoji: '👏' }, { code: '[坏笑]', emoji: '😏' },
  { code: '[哈欠]', emoji: '🥱' }, { code: '[委屈]', emoji: '🥺' },
  { code: '[快哭了]', emoji: '😢' }, { code: '[阴险]', emoji: '😈' },
  { code: '[亲亲]', emoji: '😘' }, { code: '[可怜]', emoji: '🥺' }
];

@Component
export struct SmileyPanel {
  // onSelect 回调：点表情时把 code（如 [微笑]）追加到编辑框
  onSelect: (code: string) => void = () => {};

  @State packs: SmileyPack[] = [];
  @State currentPackIndex: number = 0;
  @State loading: boolean = true;
  @State useFallback: boolean = false;

  async aboutToAppear() {
    await this.loadPacks();
  }

  async loadPacks() {
    this.loading = true;
    try {
      const list = await forumRepository.smileyPacks();
      if (list && list.length > 0) {
        this.packs = list;
        this.useFallback = false;
      } else {
        this.useFallback = true;
      }
    } catch (e) {
      this.useFallback = true;
    } finally {
      this.loading = false;
    }
  }

  getCurrentItems(): Smiley[] {
    if (this.packs.length === 0 || this.currentPackIndex >= this.packs.length) {
      return [];
    }
    return this.packs[this.currentPackIndex].items || [];
  }

  build() {
    Column() {
      if (this.loading) {
        Row() {
          LoadingProgress().width(24).height(24).color(MtfColors.primary)
          Text('加载表情…').fontSize(12).fontColor(MtfColors.textLight).margin({ left: 6 })
        }.height(40).justifyContent(FlexAlign.Center).width('100%')
      } else if (this.useFallback) {
        // 降级：显示 emoji
        this.renderFallback()
      } else if (this.packs.length === 0) {
        Row() {
          Text('表情加载失败').fontSize(12).fontColor(MtfColors.textLight)
        }.height(40).justifyContent(FlexAlign.Center).width('100%')
      } else {
        // 真实表情：多 pack 切换
        if (this.packs.length > 1) {
          Scroll() {
            Row() {
              ForEach(this.packs, (pack: SmileyPack, index: number) => {
                Text(pack.name || ('表情 ' + (index + 1)))
                  .fontSize(12)
                  .fontColor(this.currentPackIndex === index ? MtfColors.primary : MtfColors.textSubColor)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .borderRadius(10)
                  .backgroundColor(this.currentPackIndex === index ? MtfColors.primaryLight : 'transparent')
                  .margin({ right: 6 })
                  .onClick(() => { this.currentPackIndex = index; })
              }, (pack: SmileyPack, index: number) => pack.id || ('p_' + index))
            }.padding({ left: 10, right: 10, top: 4, bottom: 4 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
        }

        Grid() {
          ForEach(this.getCurrentItems(), (item: Smiley) => {
            GridItem() {
              Image(item.url)
                .width(28).height(28)
                .objectFit(ImageFit.Contain)
                .onError(() => {})
                .onClick(() => { this.onSelect(item.code); })
            }
          }, (item: Smiley) => item.code)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .padding(10)
        .height(220)
        .backgroundColor(MtfColors.bgWhiteColor)
      }
    }
    .width('100%')
  }

  @Builder renderFallback() {
    Grid() {
      ForEach(FALLBACK_ITEMS, (item: FallbackItem) => {
        GridItem() {
          Text(item.emoji).fontSize(24).textAlign(TextAlign.Center).width('100%').height('100%')
            .onClick(() => { this.onSelect(item.code); })
        }
      }, (item: FallbackItem) => item.code)
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .rowsGap(8)
    .columnsGap(8)
    .padding(10)
    .height(220)
    .backgroundColor(MtfColors.bgWhiteColor)
  }
}

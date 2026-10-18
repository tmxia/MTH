import { MtfColors } from './Theme';

@Component
export struct SmileyPanel {
  // 常用 Discuz 表情映射表
  private smiles: Array<{code: string, emoji: string}> = [
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
    { code: '[憨笑]', emoji: '😄' }, { code: '[大兵]', emoji: '🫡' },
    { code: '[奋斗]', emoji: '💪' }, { code: '[疑问]', emoji: '❓' },
    { code: '[嘘]', emoji: '🤫' }, { code: '[晕]', emoji: '😵' },
    { code: '[折磨]', emoji: '😫' }, { code: '[衰]', emoji: '😩' },
    { code: '[骷髅]', emoji: '💀' }, { code: '[敲打]', emoji: '🔨' },
    { code: '[再见]', emoji: '👋' }, { code: '[擦汗]', emoji: '😅' },
    { code: '[抠鼻]', emoji: '👃' }, { code: '[鼓掌]', emoji: '👏' },
    { code: '[糗大了]', emoji: '😅' }, { code: '[坏笑]', emoji: '😏' },
    { code: '[左哼哼]', emoji: '🐷' }, { code: '[右哼哼]', emoji: '🐷' },
    { code: '[哈欠]', emoji: '🥱' }, { code: '[鄙视]', emoji: '🖕' },
    { code: '[委屈]', emoji: '🥺' }, { code: '[快哭了]', emoji: '😢' },
    { code: '[阴险]', emoji: '😈' }, { code: '[亲亲]', emoji: '😘' },
    { code: '[吓]', emoji: '😱' }, { code: '[可怜]', emoji: '🥺' }
  ];

  @Prop onSelect: (code: string) => void = () => {};

  build() {
    Grid() {
      ForEach(this.smiles, (item) => {
        GridItem() {
          Text(item.emoji).fontSize(24).textAlign(TextAlign.Center).width('100%').height('100%')
            .onClick(() => {
              this.onSelect(item.code);
            })
        }
      }, (item) => item.code)
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .rowsGap(10)
    .columnsGap(10)
    .padding(15)
    .height(220)
    .backgroundColor(MtfColors.bgWhiteColor)
  }
}

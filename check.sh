#!/bin/bash
echo "⏳ 准备检查 ArkTS 语法..."
rm -rf check_tmp && mkdir check_tmp
find entry/src/main/ets -name "*.ets" -exec bash -c '
  for f; do
    mkdir -p "check_tmp/$(dirname "$f")"
    cp "$f" "check_tmp/${f%.ets}.ts"
  done
' _ {} +

# 运行检查，将详细输出存入 $HOME 目录
LOG_ERR="$HOME/.tsc_error.log"
LOG_FILTERED="$HOME/.tsc_filtered.log"

tsc --noEmit -p tsconfig.json > "$LOG_ERR" 2>&1
RESULT=$?
rm -rf check_tmp

if [ $RESULT -eq 0 ]; then
  echo "✅ 语法完美，没有错误！"
  exit 0
fi

# 过滤掉 TS1xxx（ArkTS 专属语法误报）和 1146
# 只保留 TS2xxx (类型错误、变量未定义、属性不存在等真正的逻辑错误)
grep -E "error TS[2-9]" "$LOG_ERR" > "$LOG_FILTERED"

COUNT=$(wc -l < "$LOG_FILTERED" | tr -d ' ')
if [ "$COUNT" -eq 0 ]; then
  echo "✅ 未发现明显的逻辑/类型错误 (已过滤 ArkTS 专属语法误报)。"
  echo "👉 若想查看所有原始报错，请查看 ~/.tsc_error.log"
else
  echo "❌ 发现 $COUNT 个逻辑/类型错误："
  # 限制输出前 20 行
  head -n 20 "$LOG_FILTERED"
  if [ "$COUNT" -gt 20 ]; then
    echo "   ... 省略剩余报错，完整日志请查看 ~/.tsc_filtered.log"
  fi
fi

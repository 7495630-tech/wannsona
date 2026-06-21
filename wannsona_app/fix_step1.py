import re

path = "lib/main.dart"

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

    # 「_buildTodoRow(), const SizedBox(height: 80), ]), ), ),」の並びを探す
    # Columnの閉じの後、SingleChildScrollViewの閉じの前に、3つの閉じカッコを挿入する

    pattern = re.compile(
        r'(_buildTodoRow\(\),\s*'
            r'const SizedBox\(height:\s*80\),\s*'
                r'\]\),)(\s*)'           # ← Columnの閉じ
                    r'(\),)(\s*)'            # ← SingleChildScrollViewの閉じ
                        r'(\),)'                 # ← RefreshIndicatorの閉じ
                        )

                        matches = pattern.findall(content)
                        print("matches found:", len(matches))

                        if len(matches) != 1:
                            print("STOP: expected exactly 1 match")
                                exit(1)

                                # 置換：Columnの閉じの直後に閉じカッコを3つ追加
                                def replacer(m):
                                    column_close = m.group(1)      # ]),
                                        ws1 = m.group(2)
                                            scsv_close = m.group(3)        # ),
                                                ws2 = m.group(4)
                                                    refresh_close = m.group(5)     # ),
                                                        return (
                                                                column_close + ws1 +
                                                                        '),\n                      ),\n                    ),' + ws1 +
                                                                                scsv_close + ws2 +
                                                                                        refresh_close
                                                                                            )

                                                                                            new_content = pattern.sub(replacer, content)

                                                                                            with open(path, "w", encoding="utf-8") as f:
                                                                                                f.write(new_content)

                                                                                                print("OK: closed brackets added")
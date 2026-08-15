# War Rig Transport

Factorio 2.0向けのトレーラーMODです。

War Rig風の車両版トレーラーと、列車版のRail War Rigを追加します。車両版はヘッドを設置すると荷台が自動生成され、走行中はスクリプトで連結追従します。列車版は通常の機関車・貨車と同じ鉄道システム上で動作します。

## 要件

- Factorio 2.0
- MOD名: `War Rig Transport`
- 現在のバージョン: `0.1.0`

## 追加される主な要素

### 車両版トレーラー

- `Semi-Trailer`
  - プロトタイプ名: `trailer-head`
  - ヘッド1台 + 荷台1台
- `Double-Trailer`
  - プロトタイプ名: `double-trailer-head`
  - ヘッド1台 + 荷台2台
- `Triple-Trailer`
  - プロトタイプ名: `triple-trailer-head`
  - ヘッド1台 + 荷台3台

荷台は内部的には `trailer-cargo` として生成されますが、通常のクラフト対象としてユーザーに見せるためのアイテムではありません。ヘッドを設置すると必要な荷台と衝突判定用プロキシが自動で作られます。

### 列車版 Rail War Rig

- `Rail War Rig`
  - プロトタイプ名: `trailer-rail-locomotive`
  - 通常の燃料で走る機関車
- `Rail Cargo Trailer`
  - プロトタイプ名: `trailer-rail-cargo-wagon`
  - 貨物用のWar Rig風貨車
- `Rail Fluid Trailer`
  - プロトタイプ名: `trailer-rail-fluid-wagon`
  - 流体用のWar Rig風貨車
- `Road rails`
  - プロトタイプ名: `trailer-road-rails`
  - 道路風の専用線路

Rail War Rigは専用線路だけでなく、通常の線路上も走行できます。専用線路は主に見た目を合わせるためのものです。

## 研究

- `Semi-Trailer`
  - 前提: `Automobilism`
  - コスト: 赤緑サイエンス x100
  - 解放: `Semi-Trailer`
- `Double-Trailer`
  - 前提: `Semi-Trailer`
  - コスト: 赤緑サイエンス x200
  - 解放: `Double-Trailer`
- `Triple-Trailer`
  - 前提: `Double-Trailer`
  - コスト: 赤緑サイエンス x300
  - 解放: `Triple-Trailer`
- `Rail War Rig`
  - 前提: `Automated Rail Transportation`、`Fluid Wagon`
  - コスト: 赤緑サイエンス x250
  - 解放: Rail War Rig機関車、貨車、流体貨車、Road rails

## レシピ概要

### 車両版

- `Semi-Trailer`
  - Engine unit x8
  - Iron gear wheel x20
  - Steel plate x20
- `Double-Trailer`
  - Engine unit x12
  - Iron gear wheel x30
  - Steel plate x30
- `Triple-Trailer`
  - Engine unit x16
  - Iron gear wheel x40
  - Steel plate x40

### 列車版

列車版は純正の機関車・貨車・流体貨車の約1.5倍を目安にしています。

- `Rail War Rig`
  - Engine unit x30
  - Electronic circuit x15
  - Steel plate x45
- `Rail Cargo Trailer`
  - Iron gear wheel x15
  - Iron plate x30
  - Steel plate x30
- `Rail Fluid Trailer`
  - Iron gear wheel x15
  - Steel plate x24
  - Pipe x12
  - Storage tank x2

## 車両版の挙動

車両版トレーラーは、ヘッドの位置・向き・速度をもとに荷台位置を毎tick計算します。

- ヘッドはFactorio標準の車両物理で動きます。
- 荷台はスクリプトで追従します。
- 荷台の衝突は、非表示の衝突プロキシで処理します。
- 荷台へのダメージ判定も衝突プロキシで受け、対応する見える荷台の耐久力へ反映します。
- セミ、ダブル、トリプルは同じ追従ロジックを使い、荷台数とヘッド重量で差を出しています。
- 荷台のインベントリにはプレイヤーやインサーターがアクセスできます。

## 撤去・破壊

車両版トレーラーはリンク単位で扱います。

- ヘッドを撤去すると、リンクされた全ての荷台と衝突プロキシも撤去されます。
- 荷台を撤去しても、ヘッドを含めたリンク全体が撤去されます。
- 撤去時は、ヘッドアイテムと各車両に入っていたアイテムが撤去バッファへ返却されます。
- 荷台用の内部アイテムは返却されません。
- 破壊時は、リンクされた全てのヘッド・荷台・衝突プロキシが破壊され、内部のアイテムはロストします。

## デバッグ描画

`scripts/trailer_manager.lua` の `DEBUG_RENDERING` を切り替えることで、衝突判定やヒッチ位置などのデバッグ描画をON/OFFできます。

- `true`: 衝突枠、ヒッチ、車軸、詰まり診断を描画
- `false`: 新しいデバッグ描画を行わず、既存の描画もクリア

通常プレイでは `false` 推奨です。

## 既知の制限

- 車両版トレーラーは完全なネイティブ連結車両ではなく、荷台追従はスクリプト制御です。
- ネイティブ車両と同等の衝突ダメージ、木のなぎ倒し、車両衝突挙動はまだ完全には実装していません。
- 荷台は車両本体と別エンティティのため、荷台重量はヘッドのネイティブ車両物理には直接加算されません。
- Road railsは見た目用の専用線路で、Rail War Rig専用の走行制限はありません。

## ライセンスと素材

War Rig関連素材とRoad rails関連素材は、TheKingJo氏のMODを参照・利用しています。

- `kj_warrig`
- `kj_vehicles`
- ライセンス: CC BY-NC-SA 4.0

詳細は `THIRD_PARTY_LICENSES.md` を参照してください。

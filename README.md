# War Rig Transport

![War Rig Transport](thumbnail.png)

Factorio 2.0向けのWar Rig輸送MODです。

自由走行できる **Semi / Double / Triple Trailer** と、通常の鉄道システムで使用できる **Rail War Rig**、貨物・流体トレーラー、道路風レールを追加します。

## Features

### Road Trailers

車両版は通常の車と同じように自由に運転できます。ヘッドを設置すると必要な荷台が自動生成され、走行中は各荷台が前方車両を追従します。

- **Semi-Trailer** — ヘッド + 荷台1台
- **Double-Trailer** — ヘッド + 荷台2台
- **Triple-Trailer** — ヘッド + 荷台3台
- 各荷台は **100スロット** の独立したインベントリを持ちます
- プレイヤーから直接アクセスでき、インサーターによる搬入・搬出にも対応します
- Double / Tripleでは後続荷台が直前の荷台を追従するため、それぞれ独立して折れ曲がります

### Rail War Rig

列車版はFactorio標準のrolling stockとして動作します。

- **Rail War Rig** — 通常燃料を使用する機関車
- **Rail Cargo Trailer** — 100スロットの貨物貨車
- **Rail Fluid Trailer** — 50,000 fluidの流体貨車
- **Road rails** — War Rig向けの道路風レール

Rail War Rigと各貨車は通常の線路でも使用できます。Road railsも通常の鉄道システムとして動作するため、専用の列車制御や独自スケジュールはありません。

## Requirements

- Factorio 2.0
- Mod ID: `War_Rig_Transport`
- Dependencies: `base >= 2.0`

## How to use

### Road Trailers

1. `Automobilism` を研究します。
2. `Semi-Trailer` を研究して製作します。
3. Semi-Trailerを設置すると荷台が自動生成されます。
4. 荷台へプレイヤーまたはインサーターでアイテムを積み込みます。
5. さらに長い編成が必要なら、`Double-Trailer`、`Triple-Trailer` を順に研究します。

荷台を個別にクラフトして連結する方式ではありません。Semi / Double / Tripleはそれぞれ独立した車両アイテムです。

### Rail War Rig

1. バニラの鉄道技術を進め、`Automated Rail Transportation` と `Fluid Wagon` を研究します。
2. `Rail War Rig` を研究します。
3. Rail War Rig、Rail Cargo Trailer、Rail Fluid Trailer、Road railsがまとめて解禁されます。
4. 通常の機関車・貨車と同じ方法で線路上へ配置し、列車を編成します。

## Research

| Technology | Prerequisites | Cost | Unlocks |
| --- | --- | --- | --- |
| Semi-Trailer | Automobilism | Automation + Logistic ×100 | Semi-Trailer |
| Double-Trailer | Semi-Trailer | Automation + Logistic ×200 | Double-Trailer |
| Triple-Trailer | Double-Trailer | Automation + Logistic ×300 | Triple-Trailer |
| Rail War Rig | Automated Rail Transportation + Fluid Wagon | Automation + Logistic ×250 | Locomotive, Cargo Trailer, Fluid Trailer, Road rails |

## Recipes

| Item | Ingredients |
| --- | --- |
| Semi-Trailer | Engine unit ×8, Iron gear wheel ×20, Steel plate ×20 |
| Double-Trailer | Engine unit ×12, Iron gear wheel ×30, Steel plate ×30 |
| Triple-Trailer | Engine unit ×16, Iron gear wheel ×40, Steel plate ×40 |
| Rail War Rig | Engine unit ×30, Electronic circuit ×15, Steel plate ×45 |
| Rail Cargo Trailer | Iron gear wheel ×15, Iron plate ×30, Steel plate ×30 |
| Rail Fluid Trailer | Iron gear wheel ×15, Steel plate ×24, Pipe ×12, Storage tank ×2 |

## Road Trailer behavior

Road Trailers use a hybrid implementation:

- The head uses Factorio's normal `car` physics.
- Visible cargo trailers are separate scripted entities.
- Trailer position and orientation are calculated every tick from the movement of the vehicle in front of them.
- Hidden collision proxies provide obstacle collision for the trailers.
- Trailer damage received through the proxy is reflected onto the visible cargo trailer.
- Semi / Double / Triple share the same trailer-following system; their main differences are trailer count and head weight.

Detailed implementation notes are in [SPEC.md](SPEC.md).

## Known limitations

- Road Trailers are not native physically-jointed vehicles; trailer articulation is script-controlled.
- Native vehicle behavior such as impact damage, tree destruction, and vehicle-to-vehicle collision is not reproduced perfectly by the scripted trailer proxies.
- Trailer entity weight does not automatically contribute to the head's native `car` mass, so Semi / Double / Triple use different head weights to approximate the heavier consists.
- Road rails are visual variants of normal rails. Rail War Rig is not restricted to them.
- Road Trailer removal/destruction behavior should be regression-tested when changing runtime linkage code because multiple entities are managed as one logical consist.

## Development

Implementation details, prototype names, tuning constants, runtime storage layout, collision handling, and required in-game regression tests are documented in [SPEC.md](SPEC.md).

## License and credits

War Rig Transport is licensed under **[CC BY-NC-SA 4.0](LICENSE)**.

Vehicle graphics, icons, sounds, minimap assets, and road-rail artwork are derived from or redistributed from TheKingJo's Factorio mods:

- `King Jo's War Rig Truck` (`kj_warrig`)
- `King Jo's Vehicles` (`kj_vehicles`)

The upstream material is also distributed under **CC BY-NC-SA 4.0**. Detailed attribution and the list of reused files are documented in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

War Rig Transport is an independent derivative project and is not endorsed by the original mod authors.

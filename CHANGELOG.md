# Changelog

## [0.2.1](https://github.com/glindstedt/obazel.nvim/compare/v0.2.0...v0.2.1) (2026-07-16)


### Bug Fixes

* run `bazel query` asynchronously to avoid blocking the UI ([#14](https://github.com/glindstedt/obazel.nvim/issues/14)) ([6ede640](https://github.com/glindstedt/obazel.nvim/commit/6ede640ae21ede633fe06d8043d6aa4b61808127))
* support `MODULE.bazel`, `REPO.bazel`, and `WORKSPACE.bazel` as workspace roots ([#12](https://github.com/glindstedt/obazel.nvim/issues/12)) ([2a232b1](https://github.com/glindstedt/obazel.nvim/commit/2a232b170e17fee3f6ca41615b66987a55a2a248))
* update to current overseer.nvim template provider API ([#11](https://github.com/glindstedt/obazel.nvim/issues/11)) ([f2d624d](https://github.com/glindstedt/obazel.nvim/commit/f2d624d5d9cff47f2ee6ac1f5cf08f3522b69d7b)), closes [#9](https://github.com/glindstedt/obazel.nvim/issues/9) [#10](https://github.com/glindstedt/obazel.nvim/issues/10)

## [0.2.0](https://github.com/glindstedt/obazel.nvim/compare/v0.1.1...v0.2.0) (2025-07-02)


### Features

* support BUILD in addition to BUILD.bazel ([4f055b3](https://github.com/glindstedt/obazel.nvim/commit/4f055b3aab6bb9303c28c29fbfe652a70a5b58c0))

## [0.1.1](https://github.com/glindstedt/obazel.nvim/compare/v0.1.0...v0.1.1) (2025-01-19)


### Bug Fixes

* health should check internal config ([d4d727f](https://github.com/glindstedt/obazel.nvim/commit/d4d727f031ea163f38dd7719339dae8d3f5d603a))

## [0.1.0](https://github.com/glindstedt/obazel.nvim/compare/v0.0.1...v0.1.0) (2025-01-18)


### Features

* add vimdoc ([52c3fbd](https://github.com/glindstedt/obazel.nvim/commit/52c3fbd0196872670bd6f56954f3b34eed46df91))
* **ci:** add luacheck action ([de6a6c3](https://github.com/glindstedt/obazel.nvim/commit/de6a6c3d93d4f7558b748d6c45e0671b2c436880))
* **ci:** add stylua check action ([fb1cfd0](https://github.com/glindstedt/obazel.nvim/commit/fb1cfd0a31abcc674eb7c4f3639190c0650c008f))


### Bug Fixes

* check and format all lua files ([b3e76ec](https://github.com/glindstedt/obazel.nvim/commit/b3e76ec536012eef2c9605e9f781a8cb04462ea8))
* shadowed variable ([0619e91](https://github.com/glindstedt/obazel.nvim/commit/0619e919dc5debc5306b61f1c6de7ab862a7943b))

## 0.0.1 (2025-01-15)


### Features

* initial commit ([b887086](https://github.com/glindstedt/obazel.nvim/commit/b887086be08bc1afba9c1760d780b34143b4c74c))


### Miscellaneous Chores

* release 0.0.1 ([260e606](https://github.com/glindstedt/obazel.nvim/commit/260e606ef7b13402e80f811de782ab55cc1f863a))

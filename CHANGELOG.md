## [1.1.0]

- Adding Middleware support. Thanks to the PR from ([appinteractive](https://github.com/appinteractive))

## [1.0.2]

- protocols added to websocket connection to bypass warnings ([#26](https://github.com/duhanbalci/surrealdb_flutter/issues/26))

## [1.0.1]

- Updated readme
- `signin` method now returns `String` instead of `Object?`

## [1.0.0]

- **Breaking:** Update for SurrealDB 2.0. Thanks to the PR from [kalucky0](https://github.com/kalucky0)

## [0.8.0]

- **Breaking:** `change` method is now `merge`.
- **FIX**: ([#20](https://github.com/duhanbalci/surrealdb_flutter/issues/20))
- `patch` method added.

## [0.7.0]

- live query stream support added

## [0.6.2]

- Fixed signin command to use namespace, database and scope parameters

## [0.6.1]

- Fixed signup command to use proper params ([#12](https://github.com/duhanbalci/surrealdb_flutter/pull/12))

## [0.6.0]

- **Breaking:** `signin` and `signup` methods parameters are now named parameters for supporting scope authentication. Now you can pass `namespace`,`database`,`scope` and `extra` parameters to `signin` and `signup` methods. `extra` parameter is `Map` type and everyting you put in this map will be sent to server.

## [0.5.0]

- Now surrealdb has optional `options` parameter in constructor. You can set timeout duration with it for all rpc calls.

## [0.4.8]

- fix: selecting single record throws exception on nightly builds ([#4](https://github.com/duhanbalci/surrealdb_flutter/pull/6))

## [0.4.7]

- change ping return type to void for future surrealdb builds ([#4](https://github.com/duhanbalci/surrealdb_flutter/pull/4))

## [0.4.6]

- fixed ([#2](https://github.com/duhanbalci/surrealdb_flutter/pull/2))

## 0.4.5

- update readme

## 0.4.4

- fix example

## 0.4.3

- fix example & readme

## 0.4.2

- update readme

## 0.4.1

- remove print statements

## 0.4.0

- unused codes removed
- unused dependencies removed

## 0.3.5

- Initial implementations

## 0.0.1

- Init

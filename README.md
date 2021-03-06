# GPSandMap

Using GPS module and show location in My iPhone

### 已完成

- 联网
- 登录、地图页面分开
- 实现实时、历史、停止、待机四个功能
- 在地图页面显示当前网络状态
- 点击历史页面，弹出输入历史轨迹查询时间页面
- 历史轨迹显示：如果轨迹坐标中有坏点（不在中国境内的点），会自动剔除掉
- 历史轨迹数据优化：
    - 历史轨迹数据只读取GPS坐标，GPRS坐标不读取
    - 实时定位如果没有GPS坐标就显示GPRS坐标
- 历史轨迹查询页面优化：
    - 将历史轨迹查询页面中查询时间保存到手机中，再次重新进入该页面时显示最近一次的查询时间设置。
    - 修复了小bug：如果查询时间为空就打印提醒：查询时间不能为空
- 用户登录密码自动保存：
    - 用户第一次登录，用户点击“登录”按钮后会自动保存密码
    - 如果该用户名​之前登录过，在填写完用户名后会，系统自动填写密码
    - 如果用户更改了密码，点击“登录”按钮后，系统会自动更新该用户名下的新密码
    - 取消了横屏模式，即app只显示竖屏模式

### 待解决问题

- 登录时，如果用户名不存在或者用户密码错误，给出相应的提示
- 如果历史轨迹GPS坐标不连续，中间混有GPRS坐标，则地图上历史轨迹以多段不同颜色的轨迹显示
- 添加离线地图功能
- 历史轨迹查询页面点击“查询“按钮前检查时间的长度、格式等是否符合要求，如果不符合要求，呈现alertView提醒
- 显示内部工作过程，如：读取历史轨迹点坐标集时，如果坐标点数量太多，耗费时间过长，在用户界面显示提醒“正在读取坐标信息，请稍候”
- 历史轨迹查询时间页面输入框键盘自动消除功能待添加
- ViewController代码比较混乱，注释不详细

### 版本说明

- v1.05 增加保存密码功能
- v1.04 历史轨迹查询页面优化
- v1.03 历史轨迹数据处理优化
- v1.02 显示历史轨迹
- v1.01 实现基本功能




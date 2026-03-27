// 智能家居设备控制面板 - 严格对齐设计稿
import { promptAction } from '@kit.ArkUI'

// 设备数据模型
@Observed
class DeviceItemData {
  id: number
  name: string
  icon: string        // rawfile 图标文件名
  isOnline: boolean
  isOn: boolean
  paramLabel: string   // 参数文本，如 "亮度75%"
  type: 'power' | 'play' // 控制按钮类型
  room: string

  constructor(id: number, name: string, icon: string, isOnline: boolean, isOn: boolean,
    paramLabel: string, type: 'power' | 'play', room: string) {
    this.id = id
    this.name = name
    this.icon = icon
    this.isOnline = isOnline
    this.isOn = isOn
    this.paramLabel = paramLabel
    this.type = type
    this.room = room
  }
}

// ===== 设备卡片组件（独立封装，可复用） =====
@Component
struct DeviceCard {
  @ObjectLink device: DeviceItemData
  onToggle: () => void = () => {}

  build() {
    Row() {
      // 左侧：设备图标
      Image($rawfile(this.device.icon))
        .width(60)
        .height(60)
        .objectFit(ImageFit.Contain)
        .margin({ right: 12 })

      // 中间：名称 + 参数
      Column() {
        // 第一行：设备名称 + 在线状态
        Row() {
          Text(this.device.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          // 在线状态
          Row() {
            Image($rawfile(this.device.isOnline ? 'dot_online.png' : 'dot_offline.png'))
              .width(8)
              .height(8)
              .margin({ right: 4 })
            Text(this.device.isOnline ? '在线' : '离线')
              .fontSize(12)
              .fontColor(this.device.isOnline ? '#4CAF50' : '#9E9E9E')
          }
        }
        .width('100%')

        // 参数文本
        Text(this.device.paramLabel)
          .fontSize(13)
          .fontColor('#999999')
          .margin({ top: 8 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)

      // 右侧：控制按钮
      Image($rawfile(this.getButtonIcon()))
        .width(40)
        .height(40)
        .objectFit(ImageFit.Contain)
        .margin({ left: 12 })
        .opacity(this.device.isOnline ? 1.0 : 0.4)
        .enabled(this.device.isOnline)
        .onClick(() => {
          if (this.device.isOnline) {
            this.onToggle()
          }
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 20, bottom: 20 })
    .borderRadius(20)
    .backdropBlur(60)
    .backgroundColor('#B3FFFFFF')  // 半透明白色毛玻璃效果
    .shadow({
      radius: 16,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 4
    })
  }

  getButtonIcon(): string {
    if (!this.device.isOnline) {
      return this.device.type === 'play' ? 'btn_power_off.png' : 'btn_power_off.png'
    }
    if (this.device.type === 'play') {
      return this.device.isOn ? 'btn_pause.png' : 'btn_play.png'
    }
    return this.device.isOn ? 'btn_power_on.png' : 'btn_power_off.png'
  }
}

// ===== 主页面 =====
@Entry
@Component
struct Index {
  @State devices: DeviceItemData[] = [
    new DeviceItemData(1, '客厅主灯', 'icon_light.png', true, true, '亮度75%', 'power', '客厅'),
    new DeviceItemData(2, '卧室空调', 'icon_ac_unit.png', true, true, '温度26°C  制冷', 'power', '卧室'),
    new DeviceItemData(3, '客厅窗帘', 'icon_curtain.png', true, false, '位置50%', 'power', '客厅'),
    new DeviceItemData(4, '扫地机器人', 'icon_robot.png', true, true, '电量80%  清洁中', 'play', '全屋'),
  ]

  @State isRefreshing: boolean = false

  build() {
    Stack() {
      // 背景图
      Image($rawfile('bg.png'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // 内容层
      Column() {
        // 标题
        Text('我的智能设备')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .width('100%')
          .padding({ left: 20, top: 12, bottom: 16 })

        // 设备卡片列表 - 支持下拉刷新
        Refresh({ refreshing: $$this.isRefreshing }) {
          List({ space: 12 }) {
            ForEach(this.devices, (device: DeviceItemData) => {
              ListItem() {
                DeviceCard({
                  device: device,
                  onToggle: () => {
                    this.toggleDevice(device)
                  }
                })
              }
            }, (device: DeviceItemData) => device.id.toString())
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 20 })
          .lanes(1)
        }
        .onRefreshing(() => {
          // 模拟刷新
          setTimeout(() => {
            this.devices.forEach(d => {
              d.isOnline = true
            })
            this.isRefreshing = false
            promptAction.showToast({ message: '设备状态已刷新', duration: 2000 })
          }, 1500)
        })
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  toggleDevice(device: DeviceItemData) {
    device.isOn = !device.isOn
    // 更新参数文本
    if (device.type === 'play') {
      device.paramLabel = device.isOn ? '电量80%  清洁中' : '电量80%  已暂停'
    }
    // Toast 提示
    promptAction.showToast({
      message: `${device.name}状态已更新`,
      duration: 3000
    })
  }
}

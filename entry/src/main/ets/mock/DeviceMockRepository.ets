import { common } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { DeviceItemData } from '../model/DeviceItemData'

const TAG: string = 'DeviceMockRepository'
const MOCK_FILE_PATH: string = 'mock/devices.mock.json'
const DEVICE_ID_SPAN: number = 1000
const DEFAULT_VISIBLE_COUNT: number = 6

class DeviceSeed {
  id: number
  name: string
  icon: string
  room: string
  category: string
  type: 'power' | 'play'
  defaultOn: boolean
  defaultOnline: boolean
  metricPrefix: string
  metricUnit: string
  activeMetricBase: number
  activeMetricRange: number
  idleMetricBase: number
  idleMetricRange: number
  metricStep: number
  activeStateText: string
  idleStateText: string

  constructor(id: number, name: string, icon: string, room: string, category: string, type: 'power' | 'play',
    defaultOn: boolean, defaultOnline: boolean, metricPrefix: string, metricUnit: string,
    activeMetricBase: number, activeMetricRange: number, idleMetricBase: number, idleMetricRange: number,
    metricStep: number, activeStateText: string, idleStateText: string) {
    this.id = id
    this.name = name
    this.icon = icon
    this.room = room
    this.category = category
    this.type = type
    this.defaultOn = defaultOn
    this.defaultOnline = defaultOnline
    this.metricPrefix = metricPrefix
    this.metricUnit = metricUnit
    this.activeMetricBase = activeMetricBase
    this.activeMetricRange = activeMetricRange
    this.idleMetricBase = idleMetricBase
    this.idleMetricRange = idleMetricRange
    this.metricStep = metricStep
    this.activeStateText = activeStateText
    this.idleStateText = idleStateText
  }
}

export class DeviceMockRepository {
  static readonly fallbackSeeds: DeviceSeed[] = [
    new DeviceSeed(1, '客厅主灯', 'icon_light.png', '客厅', 'light', 'power',
      true, true, '亮度', '%', 68, 28, 0, 1, 7, '', '关闭'),
    new DeviceSeed(2, '卧室空调', 'icon_ac_unit.png', '卧室', 'ac', 'power',
      true, true, '温度', '°C', 24, 4, 28, 1, 1, '制冷', '待机'),
    new DeviceSeed(3, '客厅窗帘', 'icon_curtain.png', '客厅', 'curtain', 'power',
      false, true, '开合', '%', 30, 55, 0, 1, 11, '', '关闭'),
    new DeviceSeed(4, '扫地机器人', 'icon_robot.png', '全屋', 'robot', 'play',
      true, true, '电量', '%', 58, 32, 58, 24, 7, '清洁中', '已暂停'),
    new DeviceSeed(5, '玄关门锁', 'icon_ac.png', '玄关', 'lock', 'power',
      true, true, '电量', '%', 72, 20, 72, 20, 5, '已上锁', '未上锁'),
    new DeviceSeed(6, '儿童房加湿器', 'icon_ac.png', '儿童房', 'humidifier', 'power',
      true, true, '湿度', '%', 46, 18, 40, 6, 4, '自动', '待机'),
    new DeviceSeed(7, '餐厅音箱', 'icon_light.png', '餐厅', 'speaker', 'play',
      false, true, '音量', '%', 24, 40, 0, 1, 6, '播放中', '已暂停'),
    new DeviceSeed(8, '阳台摄像头', 'icon_robot.png', '阳台', 'camera', 'power',
      true, true, '', '', 0, 1, 0, 1, 1, '1080P  侦测中', '待机  画面关闭'),
  ]

  static cachedSeeds: DeviceSeed[] = DeviceMockRepository.fallbackSeeds

  static async getInitialDevices(context?: common.Context): Promise<DeviceItemData[]> {
    return DeviceMockRepository.getDevicesForRound(context, 0)
  }

  static getFallbackDevices(): DeviceItemData[] {
    return DeviceMockRepository.buildDevices(
      DeviceMockRepository.cachedSeeds,
      0,
      DeviceMockRepository.getVisibleCount(0, DeviceMockRepository.cachedSeeds.length)
    )
  }

  static async getDevicesForRound(context: common.Context | undefined, round: number): Promise<DeviceItemData[]> {
    let seeds = await DeviceMockRepository.loadSeeds(context)
    let visibleCount: number = DeviceMockRepository.getVisibleCount(round, seeds.length)
    return DeviceMockRepository.buildDevices(seeds, round, visibleCount)
  }

  static async appendDevices(context: common.Context | undefined, currentDevices: DeviceItemData[],
    round: number, appendCount: number): Promise<DeviceItemData[]> {
    let seeds = await DeviceMockRepository.loadSeeds(context)
    let targetCount: number = currentDevices.length + appendCount
    return DeviceMockRepository.buildDevices(seeds, round, targetCount)
  }

  static updateDeviceAfterToggle(device: DeviceItemData): void {
    let seedId: number = DeviceMockRepository.getSeedId(device.id)
    let deviceRound: number = DeviceMockRepository.getSeedCycle(device.id)
    let seed: DeviceSeed = DeviceMockRepository.findSeed(seedId)
    device.paramLabel = DeviceMockRepository.buildParamLabel(seed, seedId + deviceRound * 17, deviceRound,
      device.isOnline, device.isOn)
  }

  static async getSeedSignature(context?: common.Context): Promise<string> {
    let seeds = await DeviceMockRepository.loadSeeds(context)
    return JSON.stringify(seeds)
  }

  static async loadSeeds(context?: common.Context): Promise<DeviceSeed[]> {
    if (!context) {
      return DeviceMockRepository.cachedSeeds
    }
    try {
      let rawData: Uint8Array = context.resourceManager.getRawFileContentSync(MOCK_FILE_PATH)
      let content: string = util.TextDecoder.create('utf-8', { ignoreBOM: true }).decodeWithStream(rawData)
      let parsed = JSON.parse(content) as Record<string, Array<Record<string, string | number | boolean>>>
      let seeds: DeviceSeed[] = DeviceMockRepository.parseSeeds(parsed['devices'])
      if (seeds.length > 0) {
        DeviceMockRepository.cachedSeeds = seeds
      }
    } catch (error) {
      hilog.warn(0x0000, TAG, `load mock file failed: ${JSON.stringify(error)}`)
    }
    return DeviceMockRepository.cachedSeeds
  }

  static parseSeeds(items: Array<Record<string, string | number | boolean>> | undefined): DeviceSeed[] {
    if (!items || items.length === 0) {
      return DeviceMockRepository.fallbackSeeds
    }
    let seeds: DeviceSeed[] = []
    for (let index = 0; index < items.length; index++) {
      let item = items[index]
      let rawId: number = Number(item['id'])
      let id: number = rawId > 0 ? rawId : index + 1
      let type: 'power' | 'play' = String(item['type']) === 'play' ? 'play' : 'power'
      seeds.push(new DeviceSeed(
        id,
        DeviceMockRepository.readString(item, 'name', `设备${id}`),
        DeviceMockRepository.readString(item, 'icon', 'icon_light.png'),
        DeviceMockRepository.readString(item, 'room', '未命名房间'),
        DeviceMockRepository.readString(item, 'category', 'light'),
        type,
        DeviceMockRepository.readBoolean(item, 'defaultOn', true),
        DeviceMockRepository.readBoolean(item, 'defaultOnline', true),
        DeviceMockRepository.readString(item, 'metricPrefix', ''),
        DeviceMockRepository.readString(item, 'metricUnit', ''),
        DeviceMockRepository.readNumber(item, 'activeMetricBase', 0),
        DeviceMockRepository.readNumber(item, 'activeMetricRange', 1),
        DeviceMockRepository.readNumber(item, 'idleMetricBase', 0),
        DeviceMockRepository.readNumber(item, 'idleMetricRange', 1),
        DeviceMockRepository.readNumber(item, 'metricStep', 1),
        DeviceMockRepository.readString(item, 'activeStateText', ''),
        DeviceMockRepository.readString(item, 'idleStateText', '')
      ))
    }
    return seeds.length > 0 ? seeds : DeviceMockRepository.fallbackSeeds
  }

  static readString(item: Record<string, string | number | boolean>, key: string, fallback: string): string {
    let value = item[key]
    if (value === undefined || value === null) {
      return fallback
    }
    return String(value)
  }

  static readNumber(item: Record<string, string | number | boolean>, key: string, fallback: number): number {
    let value = Number(item[key])
    return Number.isFinite(value) ? value : fallback
  }

  static readBoolean(item: Record<string, string | number | boolean>, key: string, fallback: boolean): boolean {
    let value = item[key]
    if (value === undefined || value === null) {
      return fallback
    }
    return Boolean(value)
  }

  static getVisibleCount(round: number, seedCount: number): number {
    let total: number = seedCount > 0 ? seedCount : DeviceMockRepository.fallbackSeeds.length
    let stage: number = round % 4
    if (stage === 1) {
      return Math.min(total, 7)
    }
    if (stage === 2) {
      return Math.min(total, 8)
    }
    return Math.min(total, DEFAULT_VISIBLE_COUNT)
  }

  static buildDevices(seeds: DeviceSeed[], round: number, count: number): DeviceItemData[] {
    let source: DeviceSeed[] = seeds.length > 0 ? seeds : DeviceMockRepository.fallbackSeeds
    let result: DeviceItemData[] = []
    for (let index = 0; index < count; index++) {
      let seed: DeviceSeed = source[index % source.length]
      let cycle: number = Math.floor(index / source.length)
      result.push(DeviceMockRepository.createDevice(seed, round, cycle))
    }
    return result
  }

  static createDevice(seed: DeviceSeed, round: number, cycle: number): DeviceItemData {
    let seedId: number = seed.id + cycle * 17
    let deviceId: number = cycle * DEVICE_ID_SPAN + seed.id
    let effectRound: number = round + cycle
    let isOnline: boolean = DeviceMockRepository.getOnlineState(seed, seedId, effectRound)
    let isOn: boolean = isOnline ? DeviceMockRepository.getSwitchState(seed, effectRound) : false
    let paramLabel: string = DeviceMockRepository.buildParamLabel(seed, seedId, effectRound, isOnline, isOn)
    let name: string = cycle === 0 ? seed.name : `${seed.name}${cycle + 1}号`
    let room: string = cycle === 0 ? seed.room : `${seed.room}${cycle + 1}区`
    return new DeviceItemData(
      deviceId,
      name,
      seed.icon,
      isOnline,
      isOn,
      paramLabel,
      seed.type,
      room,
      seed.category
    )
  }

  static getSeedCycle(deviceId: number): number {
    return Math.floor(deviceId / DEVICE_ID_SPAN)
  }

  static getSeedId(deviceId: number): number {
    let seedId: number = deviceId % DEVICE_ID_SPAN
    return seedId > 0 ? seedId : deviceId
  }

  static findSeed(seedId: number): DeviceSeed {
    let matched = DeviceMockRepository.cachedSeeds.find((item: DeviceSeed) => item.id === seedId)
    return matched ?? DeviceMockRepository.fallbackSeeds[0]
  }

  static getOnlineState(seed: DeviceSeed, seedId: number, round: number): boolean {
    let cycle: number = (seedId + round) % 5
    if (seed.defaultOnline) {
      return cycle !== 0
    }
    return cycle <= 1
  }

  static getSwitchState(seed: DeviceSeed, round: number): boolean {
    if (seed.category === 'light' || seed.category === 'ac' || seed.category === 'humidifier' || seed.category === 'camera') {
      let active: boolean = (seed.id + round) % 3 !== 0
      return seed.defaultOn ? active : !active
    }
    if (seed.category === 'curtain' || seed.category === 'speaker') {
      let active: boolean = (seed.id + round) % 2 === 0
      return seed.defaultOn ? active : !active
    }
    return seed.defaultOn
  }

  static buildParamLabel(seed: DeviceSeed, seedId: number, round: number, isOnline: boolean, isOn: boolean): string {
    let parts: string[] = []
    let metricText: string = DeviceMockRepository.buildMetricText(seed, seedId, round, isOn)
    if (metricText.length > 0) {
      parts.push(metricText)
    }
    let stateText: string = isOn ? seed.activeStateText : seed.idleStateText
    if (stateText.length > 0) {
      parts.push(stateText)
    }
    let label: string = parts.length > 0 ? parts.join('  ') : seed.name
    return isOnline ? label : `${label}  设备离线`
  }

  static buildMetricText(seed: DeviceSeed, seedId: number, round: number, isOn: boolean): string {
    if (seed.metricPrefix.length === 0) {
      return ''
    }
    let base: number = isOn ? seed.activeMetricBase : seed.idleMetricBase
    let range: number = isOn ? seed.activeMetricRange : seed.idleMetricRange
    let offset: number = 0
    if (range > 1) {
      let step = seed.metricStep > 0 ? seed.metricStep : 1
      offset = (round * step + seedId * step) % range
    }
    return `${seed.metricPrefix}${base + offset}${seed.metricUnit}`
  }
}

/**
 * Lumina 主题系统 & 常量定义
 * 支持深色/浅色模式切换，知乎风格配色
 */

// 主题模式
export enum ThemeMode {
  LIGHT = 'light',
  DARK = 'dark',
}

// 存储 key
const THEME_KEY = 'lumina_theme_mode'

/**
 * 全局主题管理器
 * 通过 AppStorage 实现响应式主题切换
 */
export class ThemeManager {
  // 初始化主题（App 启动时调用）
  static init(): void {
    const saved = AppStorage.get<string>(THEME_KEY)
    if (!saved) {
      AppStorage.setOrCreate(THEME_KEY, ThemeMode.LIGHT)
    }
  }

  static getMode(): ThemeMode {
    const mode = AppStorage.get<string>(THEME_KEY)
    return mode === ThemeMode.DARK ? ThemeMode.DARK : ThemeMode.LIGHT
  }

  static setMode(mode: ThemeMode): void {
    AppStorage.setOrCreate(THEME_KEY, mode)
  }

  static toggle(): void {
    const current = ThemeManager.getMode()
    ThemeManager.setMode(current === ThemeMode.DARK ? ThemeMode.LIGHT : ThemeMode.DARK)
  }

  static isDark(): boolean {
    return ThemeManager.getMode() === ThemeMode.DARK
  }
}

// ---- 知乎风配色 ----
// 深色模式
class DarkColors {
  static readonly primary: string = '#0066FF'
  static readonly primaryLight: string = '#3D8BFF'
  static readonly primaryBg: string = '#0066FF18'
  static readonly bg: string = '#121212'
  static readonly bgCard: string = '#1E1E1E'
  static readonly bgInput: string = '#2A2A2A'
  static readonly textPrimary: string = '#E8E8F0'
  static readonly textSecondary: string = '#9898B0'
  static readonly textHint: string = '#686888'
  static readonly stardustGold: string = '#FFC53D'
  static readonly likeRed: string = '#FF4757'
  static readonly successGreen: string = '#2ED573'
  static readonly divider: string = '#2A2A35'
  static readonly overlay: string = 'rgba(0,0,0,0.6)'
  static readonly bottomBar: string = '#1A1A1A'
  static readonly tabActive: string = '#0066FF'
  static readonly tabInactive: string = '#686888'
}

// 浅色模式（知乎白）
class LightColors {
  static readonly primary: string = '#0066FF'
  static readonly primaryLight: string = '#3D8BFF'
  static readonly primaryBg: string = '#0066FF0D'
  static readonly bg: string = '#F6F6F6'
  static readonly bgCard: string = '#FFFFFF'
  static readonly bgInput: string = '#F2F3F5'
  static readonly textPrimary: string = '#1A1A1A'
  static readonly textSecondary: string = '#646464'
  static readonly textHint: string = '#999999'
  static readonly stardustGold: string = '#E6A800'
  static readonly likeRed: string = '#FF4757'
  static readonly successGreen: string = '#2ED573'
  static readonly divider: string = '#EBEBEB'
  static readonly overlay: string = 'rgba(0,0,0,0.4)'
  static readonly bottomBar: string = '#FFFFFF'
  static readonly tabActive: string = '#0066FF'
  static readonly tabInactive: string = '#999999'
}

/**
 * 按当前主题获取颜色
 * 使用方式：C.bg, C.textPrimary ...
 */
export class C {
  static get primary(): string { return ThemeManager.isDark() ? DarkColors.primary : LightColors.primary }
  static get primaryLight(): string { return ThemeManager.isDark() ? DarkColors.primaryLight : LightColors.primaryLight }
  static get primaryBg(): string { return ThemeManager.isDark() ? DarkColors.primaryBg : LightColors.primaryBg }
  static get bg(): string { return ThemeManager.isDark() ? DarkColors.bg : LightColors.bg }
  static get bgCard(): string { return ThemeManager.isDark() ? DarkColors.bgCard : LightColors.bgCard }
  static get bgInput(): string { return ThemeManager.isDark() ? DarkColors.bgInput : LightColors.bgInput }
  static get textPrimary(): string { return ThemeManager.isDark() ? DarkColors.textPrimary : LightColors.textPrimary }
  static get textSecondary(): string { return ThemeManager.isDark() ? DarkColors.textSecondary : LightColors.textSecondary }
  static get textHint(): string { return ThemeManager.isDark() ? DarkColors.textHint : LightColors.textHint }
  static get stardustGold(): string { return ThemeManager.isDark() ? DarkColors.stardustGold : LightColors.stardustGold }
  static get likeRed(): string { return ThemeManager.isDark() ? DarkColors.likeRed : LightColors.likeRed }
  static get successGreen(): string { return ThemeManager.isDark() ? DarkColors.successGreen : LightColors.successGreen }
  static get divider(): string { return ThemeManager.isDark() ? DarkColors.divider : LightColors.divider }
  static get overlay(): string { return ThemeManager.isDark() ? DarkColors.overlay : LightColors.overlay }
  static get bottomBar(): string { return ThemeManager.isDark() ? DarkColors.bottomBar : LightColors.bottomBar }
  static get tabActive(): string { return ThemeManager.isDark() ? DarkColors.tabActive : LightColors.tabActive }
  static get tabInactive(): string { return ThemeManager.isDark() ? DarkColors.tabInactive : LightColors.tabInactive }
}

// 保持旧的 Colors 类兼容（已用 C 替换的可忽略）
export class Colors {
  static get primary(): string { return C.primary }
  static get primaryLight(): string { return C.primaryLight }
  static get primaryDark(): string { return C.primaryLight }
  static readonly secondary: string = '#FFC53D'
  static get bgDark(): string { return C.bg }
  static get bgCard(): string { return C.bgCard }
  static get bgInput(): string { return C.bgInput }
  static get textPrimary(): string { return C.textPrimary }
  static get textSecondary(): string { return C.textSecondary }
  static get textHint(): string { return C.textHint }
  static get stardustGold(): string { return C.stardustGold }
  static get likeRed(): string { return C.likeRed }
  static get successGreen(): string { return C.successGreen }
  static get divider(): string { return C.divider }
  static get overlay(): string { return C.overlay }
}

// ---- 间距 / 圆角 / 字号（不变）----

export class Spacing {
  static readonly xs: number = 4
  static readonly sm: number = 8
  static readonly md: number = 12
  static readonly lg: number = 16
  static readonly xl: number = 20
  static readonly xxl: number = 24
}

export class BorderRadius {
  static readonly sm: number = 6
  static readonly md: number = 10
  static readonly lg: number = 14
  static readonly xl: number = 18
  static readonly full: number = 9999
}

export class FontSize {
  static readonly xs: number = 11
  static readonly sm: number = 13
  static readonly body: number = 15
  static readonly title: number = 16
  static readonly lg: number = 18
  static readonly xl: number = 20
  static readonly xxl: number = 24
  static readonly xxxl: number = 28
}

export class Routes {
  static readonly SPLASH: string = 'pages/SplashPage'
  static readonly INDEX: string = 'pages/Index'
  static readonly POST_DETAIL: string = 'pages/PostDetailPage'
  static readonly PUBLISH: string = 'pages/PublishPage'
  static readonly LOGIN: string = 'pages/LoginPage'
  static readonly USER_PROFILE: string = 'pages/UserProfilePage'
  static readonly STARDUST_REWARD: string = 'pages/StarDustRewardPage'
  static readonly SEARCH: string = 'pages/SearchPage'
  static readonly SETTINGS: string = 'pages/SettingsPage'

  // 项目协作（新增）
  static readonly PROJECT_SQUARE: string = 'pages/ProjectSquarePage'
  static readonly PROJECT_DETAIL: string = 'pages/ProjectDetailPage'
  static readonly TASK_BOARD: string = 'pages/TaskBoardPage'
  static readonly PUBLISH_PROJECT: string = 'pages/PublishProjectPage'
}

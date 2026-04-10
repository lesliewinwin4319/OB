/**
 * 雪花算法 (Snowflake) ID 生成器
 *
 * ID 结构（64 bit）：
 * [1 bit 符号位 = 0] [41 bit 毫秒时间戳] [10 bit 机器ID] [12 bit 序列号]
 *
 * 冷启动阶段单节点部署，machineId 固定为 1。
 * 后续多节点扩容时，通过环境变量 MACHINE_ID 区分各实例。
 */

const EPOCH = 1744000000000n; // 2026-04-07 自定义起始纪元，减小 ID 数值
const MACHINE_ID = BigInt(parseInt(process.env.MACHINE_ID || '1', 10) & 0x3ff);
const SEQUENCE_BITS = 12n;
const MACHINE_BITS = 10n;
const MAX_SEQUENCE = (1n << SEQUENCE_BITS) - 1n; // 4095

let sequence = 0n;
let lastTimestamp = -1n;

function currentTimestamp(): bigint {
  return BigInt(Date.now());
}

/**
 * 生成一个雪花 ID，返回字符串（避免 JS BigInt 精度问题）
 */
export function generateSnowflakeId(): string {
  let ts = currentTimestamp();

  if (ts === lastTimestamp) {
    sequence = (sequence + 1n) & MAX_SEQUENCE;
    if (sequence === 0n) {
      // 当前毫秒序列号耗尽，等待下一毫秒
      while (ts <= lastTimestamp) {
        ts = currentTimestamp();
      }
    }
  } else {
    sequence = 0n;
  }

  lastTimestamp = ts;

  const id =
    ((ts - EPOCH) << (MACHINE_BITS + SEQUENCE_BITS)) |
    (MACHINE_ID << SEQUENCE_BITS) |
    sequence;

  return id.toString();
}

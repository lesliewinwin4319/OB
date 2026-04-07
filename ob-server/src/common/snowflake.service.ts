import { Injectable } from '@nestjs/common';

/**
 * Snowflake ID 生成器
 *
 * 位结构（63 位有效位）：
 * - 41 bit：毫秒时间戳（相对于 EPOCH，可用约 69 年）
 * - 10 bit：机器 ID（workerId 5bit + datacenterId 5bit，本期固定为 0）
 * - 12 bit：同毫秒内序列号（最多 4096/ms）
 *
 * 最终 uid 格式：ob_{snowflakeId}
 */
@Injectable()
export class SnowflakeService {
  // 2024-01-01 00:00:00 UTC 作为起始纪元
  private readonly EPOCH = 1704067200000n;

  private readonly WORKER_ID_BITS = 5n;
  private readonly DATACENTER_ID_BITS = 5n;
  private readonly SEQUENCE_BITS = 12n;

  private readonly MAX_WORKER_ID = -1n ^ (-1n << this.WORKER_ID_BITS);
  private readonly MAX_DATACENTER_ID = -1n ^ (-1n << this.DATACENTER_ID_BITS);

  private readonly WORKER_ID_SHIFT = this.SEQUENCE_BITS;
  private readonly DATACENTER_ID_SHIFT = this.SEQUENCE_BITS + this.WORKER_ID_BITS;
  private readonly TIMESTAMP_SHIFT =
    this.SEQUENCE_BITS + this.WORKER_ID_BITS + this.DATACENTER_ID_BITS;

  private readonly SEQUENCE_MASK = -1n ^ (-1n << this.SEQUENCE_BITS);

  private readonly workerId = 0n;
  private readonly datacenterId = 0n;

  private sequence = 0n;
  private lastTimestamp = -1n;

  nextId(): string {
    let timestamp = BigInt(Date.now());

    if (timestamp < this.lastTimestamp) {
      throw new Error(
        `Clock moved backwards. Refusing to generate id for ${this.lastTimestamp - timestamp}ms`,
      );
    }

    if (timestamp === this.lastTimestamp) {
      this.sequence = (this.sequence + 1n) & this.SEQUENCE_MASK;
      if (this.sequence === 0n) {
        // 同一毫秒内序列号溢出，等到下一毫秒
        timestamp = this.tilNextMillis(this.lastTimestamp);
      }
    } else {
      this.sequence = 0n;
    }

    this.lastTimestamp = timestamp;

    const id =
      ((timestamp - this.EPOCH) << this.TIMESTAMP_SHIFT) |
      (this.datacenterId << this.DATACENTER_ID_SHIFT) |
      (this.workerId << this.WORKER_ID_SHIFT) |
      this.sequence;

    return `ob_${id.toString()}`;
  }

  private tilNextMillis(lastTimestamp: bigint): bigint {
    let timestamp = BigInt(Date.now());
    while (timestamp <= lastTimestamp) {
      timestamp = BigInt(Date.now());
    }
    return timestamp;
  }
}

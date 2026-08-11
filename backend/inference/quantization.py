import numpy as np

_QUANTIZED = (np.uint8, np.int8)


def dequantize(raw: np.ndarray, detail: dict) -> np.ndarray:
    if detail["dtype"] not in _QUANTIZED:
        return raw.astype(np.float32)
    scale, zero_point = detail["quantization"]
    if scale == 0:
        return raw.astype(np.float32)
    return (raw.astype(np.float32) - zero_point) * scale

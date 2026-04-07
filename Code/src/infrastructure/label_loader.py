from pathlib import Path


def load_labels(labels_file: Path) -> list[str]:
    labels: list[str] = []
    
    with labels_file.open("r", encoding="utf-8") as f:
        for raw_line in f:
            line = raw_line.strip()
            
            if not line:
                continue
            
            parts = line.split(maxsplit=1)
            
            if len(parts) == 2:
                labels.append(parts[1].strip())
            else:
                labels.append(parts[0].strip())
    
    return labels

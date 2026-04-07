from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from domain.entities import PredictionResult


class Screen(str, Enum):
    HOME = "home"
    HEALTH_RESULT = "health_result"
    DISEASE_RESULT = "disease_result"


@dataclass
class AppState:
    current_image: Path | None = None
    camera_armed: bool = False
    health_result: PredictionResult | None = None
    disease_result: PredictionResult | None = None
    screen_stack: list[Screen] = field(default_factory=lambda: [Screen.HOME])

    @property
    def current_screen(self) -> Screen:
        return self.screen_stack[-1]

    @property
    def can_go_back(self) -> bool:
        return len(self.screen_stack) > 1

    def push(self, screen: Screen) -> None:
        self.screen_stack.append(screen)

    def pop(self) -> None:
        if self.can_go_back:
            self.screen_stack.pop()

    def go_home(self) -> None:
        self.current_image = None
        self.camera_armed = False
        self.health_result = None
        self.disease_result = None
        self.screen_stack = [Screen.HOME]

    def clear_results(self) -> None:
        self.health_result = None
        self.disease_result = None


def is_healthy_label(label: str) -> bool:
    value = label.strip().lower()
    return value in {"healthy", "sana", "sano"}

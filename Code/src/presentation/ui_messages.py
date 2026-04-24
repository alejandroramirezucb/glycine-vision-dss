import flet as ft

class SnackbarService:
    def __init__(self, page: ft.Page) -> None:
        self._page = page

    def show(self, message: str, error: bool = False) -> None:
        self._page.snack_bar = ft.SnackBar(
            content=ft.Text(message),
            bgcolor=ft.Colors.RED_700 if error else ft.Colors.BLUE_GREY_700,
        )
        
        self._page.snack_bar.open = True
        self._page.update()

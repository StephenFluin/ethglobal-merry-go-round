import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { MgrClientComponent } from './mgr-client/mgr-client.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, MgrClientComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss',
})
export class AppComponent {
  title = 'merry-go-round';
}

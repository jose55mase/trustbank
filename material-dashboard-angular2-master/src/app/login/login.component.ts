import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from 'app/core/services/auth.service';
import { NotificationService } from 'app/core/services/Notification.service';
import { emojisglobal, textglobal } from 'app/core/text-global';
import { ToastContainerDirective, ToastrService } from 'ngx-toastr';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css'],
  providers: [AuthService],
})
export class LoginComponent implements OnInit {
  objet = new Object;
  public email: string = "";
  public password: string = ""; 
  public loginDisable: boolean = false;

  @ViewChild(ToastContainerDirective, { static: true })
  toastContainer: ToastContainerDirective;

  constructor(private router:Router, private autService: AuthService,  private notificationService : NotificationService, private toastrService: ToastrService) { }

  ngOnInit() {
    this.toastrService.overlayContainer = this.toastContainer;
  }

  onLogin(){
    let currency = new Intl.NumberFormat('USD',{
      style: 'currency',
      minimumFractionDigits: 2,
      currency: "USD"
    })
    this.loginDisable = true;
    this.autService.login(this.email, this.password).subscribe(
      
      response => {
        const data = JSON.parse(atob(response.access_token.split('.')[1])) 
        this.objet = {
          id: data.id,
          authorities: data.authorities,
          username: "",
          email: data.email,
          fistName: data.fistName,
          lastName: data.lastName,
          city: "",
          country: "",
          postal: "",
          aboutme: "",
          moneyclean: data.moneyclean,
          money:  currency.format(data.moneyclean)
        }
        localStorage.setItem("profile", JSON.stringify(this.objet))
        sessionStorage.setItem("token", response.access_token)
        this.router.navigate(['/dashboard'])
        this.notificationService.alert("", textglobal.log_user_success, 'success');
        this.loginDisable = false;  
      },
      error => {
        console.log("Error---> ",error)
        this.notificationService.alert(emojisglobal.error, textglobal.log_user_error, 'error');
        this.loginDisable = false;
      }
    )
  }

  register(){
    this.router.navigate(['/register'])
  }

}

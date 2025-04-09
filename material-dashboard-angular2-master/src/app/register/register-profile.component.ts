import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormControl, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { NotificationService } from 'app/core/services/Notification.service';
import { TransactionService } from 'app/core/services/transaction.service';
import { UserService } from 'app/core/services/user.service';
import { textglobal } from 'app/core/text-global';
import Swal from'sweetalert2';


@Component({
  selector: 'app-register-user-profile',
  templateUrl: './register-profile.component.html',
  styleUrls: ['./register-profile.component.css']
})
export class RegisterProfileComponent implements OnInit {

  public showListUser  = true;
  public showUdateUser = false;
  public listUser      = [];
  public loadProces    = false;
  private userSelected;
  public createBtn     = false;

  checkoutForm;
  data;


  currency = new Intl.NumberFormat('USD',{
    style: 'currency',
    minimumFractionDigits: 2,
    currency: "USD"
  })

  constructor(private userService: UserService, private formBuilder: FormBuilder,
    private notificationService : NotificationService,
    private transactionService: TransactionService, private router:Router,
  ) {

    this.checkoutForm = this.formBuilder.group({
      
      email: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])),

      fistName: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])), 

      lastName: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])), 

      city: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])),

      country: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])), 

      postal: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])), 

      aboutme: new FormControl('',Validators.compose([        
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])),
      
      amount: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])),

      password: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])),
      passwordConfir: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])),

      administratorManager: new FormControl('',Validators.compose([
        Validators.required   
      ])),

    });
  }

  ngOnInit() {
    this.loadProces = true;
    this.checkoutForm.reset();
  }

 

  getUserList(){
    this.userService.getListUser().subscribe(
      respone => {
        this.loadProces = false;
        console.log(respone)
        this.listUser = respone
      },
      error => {
        console.log("Error en la consulta", error)
        if(error.status == 401){
          Swal.fire({
            title: "Fin de sesion",
            text: "La sesion a finalizado vueva a iniciar sesion",
            icon: "warning"
          });
          this.router.navigate(['/login'])
        }
        if(error.status == 500){
          this.notificationService.alert("", textglobal.error, 'error');
        }
      }
    )
  }

  editUser(item){
    this.userSelected = item;
    console.log("edit --> ",item)

    this.showListUser = false;
    this.showUdateUser = true;

    this.checkoutForm.controls['email'].setValue(item.email)
    this.checkoutForm.controls['fistName'].setValue(item.fistName)
    this.checkoutForm.controls['lastName'].setValue(item.lastName)
    this.checkoutForm.controls['city'].setValue(item.city)
    this.checkoutForm.controls['country'].setValue(item.country)
    this.checkoutForm.controls['postal'].setValue(item.postal)
    this.checkoutForm.controls['aboutme'].setValue(item.aboutme)
    this.checkoutForm.controls['amount'].setValue(item.moneyclean)
    this.checkoutForm.controls['password'].setValue(item.moneyclean)
  }

  cancelReister(){
    this.router.navigate(['/login'])
  }

  

  

  create(){

    if(this.checkoutForm.value.email.length == 0){
      this.notificationService.alert("", "El campo  email es necesario", 'warning');
      return
    }

    if(this.checkoutForm.value.password.length == 0){
      this.notificationService.alert("", "El campo contraseña es necesario", 'warning');
      return
    }

    

    if(this.checkoutForm.value.password != this.checkoutForm.value.passwordConfir){
      this.notificationService.alert("", "Las credenciales no coinciden", 'warning');
      return
    }else{
      let rols = [
        {
          "id": 2,
          "name": "ROLE_USER"
        }
      ]
      const objet = {
        "password": this.checkoutForm.value.password,
        "username": "testing",
        "email": this.checkoutForm.value.email,
        "fistName": this.checkoutForm.value.fistName,
        "lastName": this.checkoutForm.value.lastName,      
        "city": this.checkoutForm.value.city,
        "country": this.checkoutForm.value.country,
        "postal": this.checkoutForm.value.postal,
        "aboutme": this.checkoutForm.value.aboutme,
        "moneyclean": this.checkoutForm.value.amount,
        "status": true,
        "foto": "",
        "documentFrom": "",
        "documentBack": "",
        "administratorManager": this.checkoutForm.value.administratorManager
        //"rols": rols
        
    }
  
    console.log(objet)
      this.userService.savaUser(objet).subscribe(
        response => {
          console.log(response.responseCode)
          if(response.responseCode === 200){
            Swal.fire({
              title: "Éxito",
              text: "Usuario Creado con exito",
              icon: "success"
            });
            this.router.navigate(['/login'])
          }else{
            Swal.fire({
              title: "Alerta",
              text: "Usuario con este correo ya esta registrado",
              icon: "warning"
            });
          }
        },
        error => {
          console.log("Error en la consulta", error)
          if(error.status == 401){
            Swal.fire({
              title: "Fin de sesion",
              text: "La sesion a finalizado vueva a iniciar sesion",
              icon: "warning"
            });
            this.router.navigate(['/login'])
          }
          if(error.status == 500){
            this.notificationService.alert("", textglobal.error, 'error');
          }
        }
      )
    }
    
  }


}

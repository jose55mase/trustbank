import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormControl, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { NotificationService } from 'app/core/services/Notification.service';
import { TransactionService } from 'app/core/services/transaction.service';
import { UserService } from 'app/core/services/user.service';
import { textglobal } from 'app/core/text-global';
import Swal from'sweetalert2';


@Component({
  selector: 'app-admin-user-profile',
  templateUrl: './admin-user-profile.component.html',
  styleUrls: ['./admin-user-profile.component.css']
})
export class AdminUserProfileComponent implements OnInit {

  public showListUser  = true;
  public showUdateUser = false;
  public listUser      = [];
  public loadProces    = false;
  private userSelected;
  public createBtn     = false;
  public statusDocument;


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

    });
  }

  ngOnInit() {
    this.loadProces = true;
    this.getUserList()
  }

  aproved(){
    let documentsAprov={
      foto: false,
      fromt: false,
      back: false
    }

    const stringFile = JSON.stringify(documentsAprov)

    console.log(stringFile)
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

    this.statusDocument = JSON.parse(item.documentsAprov)

    console.log("Validando ---_> ", this.statusDocument)

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

  cancelEditUser(){
    this.showListUser  = true;
    this.showUdateUser = false;
    this.createBtn     = false;
  }

  createUser(){
    this.showListUser = false;
    this.showUdateUser = true;
    this.createBtn = true;


    this.checkoutForm.controls['email'].setValue("")
    this.checkoutForm.controls['fistName'].setValue("")
    this.checkoutForm.controls['lastName'].setValue("")
    this.checkoutForm.controls['city'].setValue("")
    this.checkoutForm.controls['country'].setValue("")
    this.checkoutForm.controls['postal'].setValue("")
    this.checkoutForm.controls['aboutme'].setValue("")
    this.checkoutForm.controls['amount'].setValue("")
    this.checkoutForm.controls['password'].setValue("")
  }

  updateUser(){
    const objet = {
      "id": this.userSelected.id   ,
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
      "foto": this.userSelected.foto,
      "documentFrom": this.userSelected.documentFrom,
      "documentBack": this.userSelected.documentBack,
      "rols": this.userSelected.rols
  }

  console.log(objet)
    this.userService.update(objet).subscribe(
      response => {
        Swal.fire({
          title: "Éxito",
          text: "Usuario actulizado con exito",
          icon: "success"
        });
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

  create(){
    if(this.checkoutForm.value.password.length == 0){
      this.notificationService.alert("", "El campo contraseña es necesario", 'warning');
      return
    }

    if(this.checkoutForm.value.email.length == 0){
      this.notificationService.alert("", "El campo contraseña es email es necesario", 'warning');
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
        "documentBack": ""
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
    /*
    */
  }

  public documentAprove(namedocument: string){
    
    let json = JSON.parse(this.userSelected.documentsAprov)
    
    if (namedocument=="foto"){
      json.foto = true
    }else if(namedocument=="back"){
      json.back = true
    }else if(namedocument=="fromt"){
      json.fromt = true
    }
    this.statusDocument = json;
    this.userSelected.documentsAprov = JSON.stringify(json)

    this.userService.update(this.userSelected).subscribe(
      response => {
        console.log(response.responseCode)
        Swal.fire({
          title: "Éxito",
          text: "Archivo aprovado",
          icon: "success"
        });
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

  public documentRefuse(namedocument: string){
    
    let json = JSON.parse(this.userSelected.documentsAprov)
    
    if (namedocument=="foto"){
      json.foto = 'refused'
    }else if(namedocument=="back"){
      json.back = 'refused'
    }else if(namedocument=="fromt"){
      json.fromt = 'refused'
    }
    this.statusDocument = json;
    this.userSelected.documentsAprov = JSON.stringify(json)

    this.userService.update(this.userSelected).subscribe(
      response => {
        console.log(response.responseCode)
        Swal.fire({
          title: "Éxito",
          text: "Archivo rechazado",
          icon: "success"
        });
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

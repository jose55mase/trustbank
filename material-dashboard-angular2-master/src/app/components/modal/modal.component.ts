import { Component, OnInit } from '@angular/core';
import { MdbModalRef } from 'mdb-angular-ui-kit/modal';
import { FormBuilder, Validators, FormControl } from '@angular/forms';
import { NotificationService } from 'app/core/services/Notification.service';
import * as moment from 'moment';
import { textglobal } from 'app/core/text-global';
import { Router } from '@angular/router';
import { UserService } from 'app/core/services/user.service';
import Swal from'sweetalert2';
import { TransactionService } from 'app/core/services/transaction.service';



@Component({
  selector: 'app-modal',
  templateUrl: './modal.component.html',
  styleUrls: ['./modal.component.css']
})
export class ModalComponent implements OnInit {
  test : Date = new Date();
  checkoutForm;
  objet = new Object;
  loadtransaction = false;
  private userData;
  
  constructor(public modalRef: MdbModalRef<ModalComponent>, private transactionService: TransactionService,
    private notificationService : NotificationService, private userService: UserService,
    private formBuilder: FormBuilder, private router:Router) {
    this.checkoutForm = this.formBuilder.group({
      
      desription: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])),   
      
      amount: new FormControl('',Validators.compose([
        Validators.required,
        Validators.pattern("^[0-9]*$"),
        Validators.minLength(4),
        Validators.maxLength(30)   
           
      ])),

      bank: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])),

      type: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])),
    });
  }

  ngOnInit() {
    let user = JSON.parse(localStorage.getItem("profile"))
    console.log("Dashboar --> init : ",user)
    this.getUser(user.email)
  }

  onSendTransaction(){
    this.loadtransaction = true;
    let profile = JSON.parse(localStorage.getItem("profile"))

    if(this.checkoutForm.value.amount > profile.moneyclean){
      this.notificationService.alert("", textglobal.create_transaction_warning, 'warning');
      this.loadtransaction = false;
      return
    }

    

    const amount = profile.moneyclean - this.checkoutForm.value.amount
    profile.moneyclean = amount;
    this.userData.moneyclean = amount;
    console.log("Update send --> ",this.userData)

    var idesData = Date.now()
    this.objet = {
      number : idesData,
      date: moment().format('YYYY-MM-DD HH:mm:ss'),
      description : this.checkoutForm.value.desription,
      amount: this.checkoutForm.value.amount,
      banck: this.checkoutForm.value.bank,
      type: this.checkoutForm.value.type,
      status: null,
      userId: profile.id
    }

    this.transactionService.save(this.objet).subscribe(
      succes => {
        this.userService.update(this.userData).subscribe(
          response => {
            localStorage.setItem("profile", JSON.stringify(profile)) 
            let data = localStorage.getItem("transaction")
    
            if(data===null){      
              localStorage.setItem("transaction", JSON.stringify([this.objet]))
            }else{
              let array = JSON.parse(data)
              array.push(this.objet) 
              console.log(array)
              localStorage.setItem("transaction", JSON.stringify(array))
            }
            this.notificationService.alert("", textglobal.create_transaction_success, 'success');
            this.router.navigate(['/transaction'])
            this.modalRef.close()
    
            Swal.fire({
              title: "Transacción completada con éxito",
              text: "La transacción esta en proceso de aprobación.",
              icon: "success"
            });
            this.loadtransaction = false;
          },
          error => {
            this.notificationService.alert("", textglobal.error, 'error');
            this.loadtransaction = false;
          }
        )
      },
      error => {
        this.notificationService.alert("", textglobal.error, 'error');
      }
    )

    /**/
  }

  public getUser(email: string){
    this.userService.getUser(email).subscribe(
      response => {
        console.log("todo bien ", response)
        this.userData = response
      },
      error => {
        console.log("Error --> ", error)
      }
    )
  }

}
/*
this.objet = {
  "id": responseUser.id,
  "username": "usuario",
  "email": responseUser.email,
  "fistName": responseUser.fistName,
  "lastName": responseUser.lastName,      
  "city": responseUser.city,
  "country": responseUser.country,
  "postal": responseUser.postal,
  "aboutme": responseUser.aboutme,
  "moneyclean": responseUser.amount,
  "status": true,
  "foto": responseUser.foto,
  "documentFrom": responseUser.documentFrom,
  "documentBack": responseUser.documentBack,
  "rols": responseUser.rols,
  "documentsAprov": responseUser.documentsAprov,
  "money":  currency.format(data.moneyclean)
}*/
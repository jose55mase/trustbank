import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { NotificationService } from 'app/core/services/Notification.service';
import { TransactionService } from 'app/core/services/transaction.service';
import { textglobal } from 'app/core/text-global';
import Swal from'sweetalert2';

@Component({
  selector: 'app-transaction',
  templateUrl: './transaction.component.html',
  styleUrls: ['./transaction.component.css']
})
export class TransactionComponent implements OnInit {

  data = [];
  currency = new Intl.NumberFormat('USD',{
    style: 'currency',
    minimumFractionDigits: 2,
    currency: "USD"
  })


  constructor(private transactionService: TransactionService, private router:Router,
    private notificationService : NotificationService
  ) { }

  ngOnInit() {
    let profile = JSON.parse(localStorage.getItem("profile"))
    this.transactionService.getByuser(profile.id).subscribe(
      response => {
        this.data = response;
        //console.log("Data --> ", response)
      },
      error => {
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
        console.log("error", error)}
    )
  }

}

import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { NotificationService } from 'app/core/services/Notification.service';
import { TransactionService } from 'app/core/services/transaction.service';
import { textglobal } from 'app/core/text-global';
import { response } from 'express';
import Swal from'sweetalert2';

@Component({
  selector: 'app-admin-transaction',
  templateUrl: './admin-transaction.component.html',
  styleUrls: ['./admin-transaction.component.css']
})
export class AdminTransactionComponent implements OnInit {

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
    this.transactionService.getall().subscribe(
      response => {
        this.data = response;
        console.log("Data --> ", response)},
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

  public aproved(item: any) {
    item.status = 'true'
    this.transactionService.save(item).subscribe(
      response => {
        Swal.fire({
          title: "Completado",
          text: "Transacción aprobada",
          icon: "success"
        });
      },
      error=> {
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

  public refused(item: any) {
    item.status = 'false'
    this.transactionService.save(item).subscribe(
      response => {
        Swal.fire({
          title: "Completado",
          text: "Transacción rechazada",
          icon: "success"
        });
      },
      error=> {
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

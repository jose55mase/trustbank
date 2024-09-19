
import { Injectable } from '@angular/core';
import { ToastrService } from 'ngx-toastr';


@Injectable({
  providedIn: 'root'
})

export class NotificationService {

  constructor(private toastr: ToastrService) { }

  /**
   * @date (12-05-2020)
   * @author 
   * @description Metodo par mostrar las notificaciones
   * @params { strTitle, strMessage, strType } datos para el mensaje
  **/
  alert(strTitle: string, strMessage: string, strType: string) {

    this.toastr.clear();

    switch (strType) {
      case 'error':
        this.toastr.error(strMessage, strTitle);
        break;
      case 'info':
        this.toastr.info(strMessage, strTitle);
        break;
      case 'success':
        this.toastr.success(strMessage, strTitle);
        break;
      case 'warning':
        this.toastr.warning(strMessage, strTitle);
        break;
      default:
        this.toastr.info(strMessage, strTitle);
        break;
    }

  }

  
}
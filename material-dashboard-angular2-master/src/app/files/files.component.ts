import { Component, OnInit } from '@angular/core';
import { DomSanitizer } from '@angular/platform-browser';
import { Router } from '@angular/router';
import { NotificationService } from 'app/core/services/Notification.service';
import { TransactionService } from 'app/core/services/transaction.service';
import { UserService } from 'app/core/services/user.service';
import { error } from 'console';
import Swal from'sweetalert2';

@Component({
  selector: 'app-files',
  templateUrl: './files.component.html',
  styleUrls: ['./files.component.css']
})
export class FilesComponent implements OnInit {

  private imageSelected: File;
  public  imagePreviwPicture;
  public  imagePreviwDocumenOne;
  public  imagePreviwDocumentwo;
  public  data;
  public  image;
  public statusDocument;

  constructor(private sanitizer: DomSanitizer,private userService: UserService,private transactionService: TransactionService
    , private router:Router, private notificationService : NotificationService) { }

  ngOnInit() {
    this.getUserData();
    this.image =  "397e71c3-34ef-4a40-8fa4-fc2ad59971f5_killfeed.jpg";
  }

  public selectedPicture(event){
    const file = event.target.files[0]
    this.extraerBase64(file).then((imagen: any) => {
      this.imagePreviwPicture = imagen.base;
    })
    this.imageSelected = file;
    /*
    this.imageSelected = URL.createObjectURL(file)
    console.log(this.imageSelected);
    */  
  }

  public selectedDocumentOne(event){
    const file = event.target.files[0]
    this.extraerBase64(file).then((imagen: any) => {
      this.imagePreviwDocumenOne = imagen.base;
    })
    this.imageSelected = file;
    /*
    this.imageSelected = URL.createObjectURL(file)
    console.log(this.imageSelected);
    */  
  }

  public selectedDocumentTwo(event){
    const file = event.target.files[0]
    this.extraerBase64(file).then((imagen: any) => {
      this.imagePreviwDocumentwo = imagen.base;
    })
    this.imageSelected = file;
    /*
    this.imageSelected = URL.createObjectURL(file)
    console.log(this.imageSelected);
    */  
  }

  

  public getUserData() {
    const userData =  JSON.parse(localStorage.getItem("profile"))
    
    this.userService.getUser(userData.email).subscribe(
      response => {
        this.data = response
        this.statusDocument = JSON.parse(response.documentsAprov)
        console.log(this.data)      
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
          this.notificationService.alert("", "Error en el sistema", 'error');
        }
      }
    )
  }

  extraerBase64 = async ($event: any) => new Promise((resolve, reject) => {
    try {
      const unsafeImg = window.URL.createObjectURL($event);
      const image = this.sanitizer.bypassSecurityTrustUrl(unsafeImg);
      const reader = new FileReader();
      reader.readAsDataURL($event);
      reader.onload = () => {
        resolve({
          base: reader.result
        });
      };
      reader.onerror = error => {
        resolve({
          base: null
        });
      };

    } catch (e) {
      return null;
    }
  })

  public upluadFile(){
    this.userService.subirFoto(this.imageSelected,this.data.id).subscribe(
      response => {
        this.notificationService.alert("", "Completado", 'success');
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
          this.notificationService.alert("", "Error en el sistema", 'error');
        }
      }
    )
  }

  upluadFileDocumentFromt(){
    this.userService.subirdocumentFromt(this.imageSelected,this.data.id).subscribe(
      response => {
        this.notificationService.alert("", "Completado", 'success');
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
          this.notificationService.alert("", "Error en el sistema", 'error');
        }
      }
    )
  }

  upluadFileDocumentback(){
    this.userService.subirdocumentBack(this.imageSelected,this.data.id).subscribe(
      response => {
        this.notificationService.alert("", "Completado", 'success');
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
          this.notificationService.alert("", "Error en el sistema", 'error');
        }
      }
    )
  }

}

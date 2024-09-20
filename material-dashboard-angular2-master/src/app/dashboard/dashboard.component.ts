import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { ModalComponent } from 'app/components/modal/modal.component';
import { UserService } from 'app/core/services/user.service';
import * as Chartist from 'chartist';

//import { GalleryModule, GalleryComponent, ImageItem } from 'ng-gallery';
import { MdbModalRef, MdbModalService } from 'mdb-angular-ui-kit/modal';
import * as moment from 'moment';




@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent implements OnInit {
  
  //@ViewChild(GalleryComponent) gallery: GalleryComponent;

  modalRef: MdbModalRef<ModalComponent> | null = null;
  dataUserPrifile: any = {};
  calendar;
  greeting;
  currency = new Intl.NumberFormat('USD',{
    style: 'currency',
    minimumFractionDigits: 2,
    currency: "USD"
  })

  constructor( private modalService: MdbModalService, userService: UserService,private router:Router  ) { }

  openModal() {
    this.modalRef = this.modalService.open(ModalComponent)
  }

  

  startAnimationForLineChart(chart){
      let seq: any, delays: any, durations: any;
      seq = 0;
      delays = 80;
      durations = 500;

      chart.on('draw', function(data) {
        if(data.type === 'line' || data.type === 'area') {
          data.element.animate({
            d: {
              begin: 600,
              dur: 700,
              from: data.path.clone().scale(1, 0).translate(0, data.chartRect.height()).stringify(),
              to: data.path.clone().stringify(),
              easing: Chartist.Svg.Easing.easeOutQuint
            }
          });
        } else if(data.type === 'point') {
              seq++;
              data.element.animate({
                opacity: {
                  begin: seq * delays,
                  dur: durations,
                  from: 0,
                  to: 1,
                  easing: 'ease'
                }
              });
          }
      });

      seq = 0;
  };
  startAnimationForBarChart(chart){
      let seq2: any, delays2: any, durations2: any;

      seq2 = 0;
      delays2 = 80;
      durations2 = 500;
      chart.on('draw', function(data) {
        if(data.type === 'bar'){
            seq2++;
            data.element.animate({
              opacity: {
                begin: seq2 * delays2,
                dur: durations2,
                from: 0,
                to: 1,
                easing: 'ease'
              }
            });
        }
      });

      seq2 = 0;
  };

 

  ngOnInit() {
    //this.gallery.addImage({ src: 'IMAGE_SRC_URL', thumb: 'IMAGE_THUMBNAIL_URL' });
    this.dataUserPrifile = JSON.parse(localStorage.getItem("profile"))
    const token = JSON.parse(sessionStorage.getItem("token")) 
    if(token == null || token == undefined){
      this.router.navigate(['/login'])
    }
    
    
    this.dayStatus()
  }

  dayStatus() {
    this.calendar = moment().format('YYYY-MM-DD')
    console.log(moment().hour())
    if(moment().hour() < 12 ){
      this.greeting = "Buenos dias 🌤️"
    }

    if(moment().hour() >= 12 && moment().hour() < 18){
      this.greeting = "Buenos tardes 🌘"
    }

    if(moment().hour() > 18 ){
      this.greeting = "Buenos noches 🌙"
    }
    
  }

}

import { Component, OnInit } from '@angular/core';

declare const $: any;
declare interface RouteInfo {
    path: string;
    title: string;
    icon: string;
    class: string;
}
export const ROUTES: RouteInfo[] = [
    { path: '/dashboard', title: 'Dashboard',  icon: 'dashboard', class: '' },
    { path: '/transaction', title: 'Transaction',  icon:'library_books', class: '' },
    /*{ path: '/accounts', title: 'Accounts',  icon:'account_balance_wallet', class: '' },*/
    { path: '/files', title: 'Files',  icon:'inventory_2', class: '' },
    { path: '/user-profile', title: 'User Profile',  icon:'person', class: '' },

    
    

    /*
    { path: '/table-list', title: 'Table List',  icon:'content_paste', class: '' },
    { path: '/typography', title: 'Typography',  icon:'library_books', class: '' },
    { path: '/icons', title: 'Icons',  icon:'bubble_chart', class: '' },
    { path: '/maps', title: 'Maps',  icon:'location_on', class: '' },
    { path: '/notifications', title: 'Notifications',  icon:'notifications', class: '' },*/
    //{ path: '/upgrade', title: 'Upgrade to PRO',  icon:'unarchive', class: 'active-pro' },
];

export const ROUTESADMIN: RouteInfo[] = [ 
  { path: '/dashboard', title: 'Dashboard',  icon: 'dashboard', class: '' },
  { path: '/admin-transaction', title: 'Admin Transaction',  icon:'library_books', class: '' },
  { path: '/admin-profiles', title: 'Admin Profiles',  icon:'person', class: '' }
  
];

@Component({
  selector: 'app-sidebar',
  templateUrl: './sidebar.component.html',
  styleUrls: ['./sidebar.component.css']
})
export class SidebarComponent implements OnInit {
  menuItems: any[];

  constructor() { }

  ngOnInit() {
    let profile = JSON.parse(localStorage.getItem("profile"))
    console.log(profile.authorities)
    if(profile.authorities != undefined ){
      if(profile.authorities[0] === "ROLE_ADMIN"){
        this.menuItems = ROUTESADMIN.filter(menuItem => menuItem);
      }else{
        this.menuItems = ROUTES.filter(menuItem => menuItem);
      }
    }else{
      this.menuItems = ROUTES.filter(menuItem => menuItem);
    }
    
    
    
  }
  isMobileMenu() {
      if ($(window).width() > 991) {
          return false;
      }
      return true;
  };
}

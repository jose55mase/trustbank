import { HttpClient, HttpEvent, HttpHeaders, HttpRequest } from '@angular/common/http';
import { Injectable, EventEmitter } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, throwError } from 'rxjs';
import { map, catchError, tap } from 'rxjs/operators';


@Injectable({
  providedIn: 'root'
})
export class ChangeDataService {
  
  private _loginEventEmitter: EventEmitter<any> = new EventEmitter();

  get getLoginEvenEmitter(){
    return this._loginEventEmitter;
  }
  
}




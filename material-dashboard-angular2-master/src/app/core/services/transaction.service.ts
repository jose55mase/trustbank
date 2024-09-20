import { HttpClient, HttpEvent, HttpHeaders, HttpParams, HttpRequest } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, throwError } from 'rxjs';
import { map, catchError, tap } from 'rxjs/operators';


@Injectable({
  providedIn: 'root'
})
export class TransactionService {
  private URL = 'https://guardianstrustbank.com:8081/api/transaction'
  
  private httpHeaders = new HttpHeaders({ 'Content-Type': 'application/json' });
  
  constructor(private httpClient: HttpClient, private router: Router) { }
  
  private agregarAuthorizationHeader() {
    const token = sessionStorage.getItem("token")
    if (token != null) {
      return this.httpHeaders.append('Authorization', 'Bearer ' + token);
    }
    return this.httpHeaders;
  }

  


  save(transaction: any): Observable<any>{
    return this.httpClient.post<any>(`${this.URL}/save`, transaction, {headers: this.agregarAuthorizationHeader()})
  }

  update(transaction: any): Observable<any>{
    return this.httpClient.put<any>(`${this.URL}/update`, transaction, {headers: this.agregarAuthorizationHeader()})
  }

  getByuser(userid: number): Observable<any>{
    let params = new HttpParams()
      .set('idUser', userid)
    return this.httpClient.get<any>(`${this.URL}/findByUser`,  {headers: this.agregarAuthorizationHeader(),params: params})
  }

  getall(): Observable<any>{
    let params = new HttpParams()
    return this.httpClient.get<any>(`${this.URL}/findAll`,  {headers: this.agregarAuthorizationHeader(),params: params})
  }

  
}

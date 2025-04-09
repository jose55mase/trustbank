import { HttpClient, HttpEvent, HttpHeaders, HttpRequest } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, throwError } from 'rxjs';
import { map, catchError, tap } from 'rxjs/operators';


@Injectable({
  providedIn: 'root'
})
export class UserService {
  //URL = 'http://localhost:8081/api/user'
  private URL = 'http://localhost:8081/api/user'
  
  private httpHeaders = new HttpHeaders({ 'Content-Type': 'application/json' });
  
  constructor(private httpClient: HttpClient, private router: Router) { }
  
  private agregarAuthorizationHeader() {
    const token = sessionStorage.getItem("token")
    if (token != null) {
      return this.httpHeaders.append('Authorization', 'Bearer ' + token);
    }
    return this.httpHeaders;
  }


  getUser(email: string): Observable<any>{
    return this.httpClient.get<any>(`${this.URL}/getUserByEmail/${email}`, {headers: this.agregarAuthorizationHeader()})
  }


  

  subirFoto(archivo: File, id): Observable<HttpEvent<{}>> {
    let formData = new FormData();
    formData.append("archivo", archivo);
    formData.append("id", id);

    let httpHeaders = new HttpHeaders();
    const token = sessionStorage.getItem("token")
    if (token != null) {
      httpHeaders = httpHeaders.append('Authorization', 'Bearer ' + token);
    }

    const req = new HttpRequest('POST', `${this.URL}/upload`, formData, {
      reportProgress: true,
      headers: httpHeaders
    });

    return this.httpClient.request(req).pipe(
      catchError(e => {
        return throwError(e);
      })
    );

  }

  subirdocumentFromt(archivo: File, id): Observable<HttpEvent<{}>> {

    let formData = new FormData();
    formData.append("archivo", archivo);
    formData.append("id", id);

    let httpHeaders = new HttpHeaders();
    const token = sessionStorage.getItem("token")
    if (token != null) {
      httpHeaders = httpHeaders.append('Authorization', 'Bearer ' + token);
    }

    const req = new HttpRequest('POST', `${this.URL}/upload/documentFrom`, formData, {
      reportProgress: true,
      headers: httpHeaders
    });

    return this.httpClient.request(req).pipe(
      catchError(e => {
        return throwError(e);
      })
    );

  }

  subirdocumentBack(archivo: File, id): Observable<HttpEvent<{}>> {

    let formData = new FormData();
    formData.append("archivo", archivo);
    formData.append("id", id);

    let httpHeaders = new HttpHeaders();
    const token = sessionStorage.getItem("token")
    if (token != null) {
      httpHeaders = httpHeaders.append('Authorization', 'Bearer ' + token);
    }

    const req = new HttpRequest('POST', `${this.URL}/upload/documentBack`, formData, {
      reportProgress: true,
      headers: httpHeaders
    });

    return this.httpClient.request(req).pipe(
      catchError(e => {
        return throwError(e);
      })
    );

  }

  update(user: any): Observable<any>{
    return this.httpClient.put<any>(`${this.URL}/update`, user, {headers: this.agregarAuthorizationHeader()})
  }

  getListUser(){
    return this.httpClient.get<any>(`${this.URL}/findAll`, {headers: this.agregarAuthorizationHeader()})
  }

  
  getListUserAdministratorManager(){
    let user = JSON.parse(localStorage.getItem("profile"))
    return this.httpClient.get<any>(`${this.URL}/findByAdministratorManager/${user.id}`, {headers: this.agregarAuthorizationHeader()})
  }

  savaUser(user: any): Observable<any>{
    return this.httpClient.post<any>(`${this.URL}/save`, user)
  }

  
}




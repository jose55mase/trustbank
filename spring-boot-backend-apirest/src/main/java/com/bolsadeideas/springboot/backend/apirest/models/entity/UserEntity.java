package com.bolsadeideas.springboot.backend.apirest.models.entity;

import javax.persistence.*;
import java.io.Serializable;
import java.util.List;

@Entity
@Table(name = "usersbank")
public class UserEntity implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    //@Column(unique = true, length = 20)
    private String username;

    @Column(unique = true, length = 40)
    private String email;

    @Column(length = 20)
    private String fistName;

    @Column(length = 20)
    private String lastName;

    private String documentsAprov;

    @Column(length = 20)
    private String document;
    private String city;
    private String country;
    private String postal;
    private String aboutme;
    @Column(length = 60)
    private String password;
    private Integer moneyclean;
    private Boolean status;

    private String foto;
    private String documentFrom;
    private String documentBack;
    @Column(length = 10)
    private Integer administratorManager;

    @ManyToMany(fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    private List<RolEntity> rols;


    public String getDocumentsAprov() {
        return documentsAprov;
    }

    public void setDocumentsAprov(String documentsAprov) {
        this.documentsAprov = documentsAprov;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getFistName() {
        return fistName;
    }

    public void setFistName(String fistName) {
        this.fistName = fistName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public String getDocument() {
        return document;
    }

    public void setDocument(String document) {
        this.document = document;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country;
    }

    public String getPostal() {
        return postal;
    }

    public void setPostal(String postal) {
        this.postal = postal;
    }

    public String getAboutme() {
        return aboutme;
    }

    public void setAboutme(String aboutme) {
        this.aboutme = aboutme;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public Integer getMoneyclean() {
        return moneyclean;
    }

    public void setMoneyclean(Integer moneyclean) {
        this.moneyclean = moneyclean;
    }

    public Boolean getStatus() {
        return status;
    }

    public void setStatus(Boolean status) {
        this.status = status;
    }

    public List<RolEntity> getRols() {
        return rols;
    }

    public String getFoto() {
        return foto;
    }

    public void setFoto(String foto) {
        this.foto = foto;
    }

    public String getDocumentFrom() {
        return documentFrom;
    }

    public void setDocumentFrom(String documentFrom) {
        this.documentFrom = documentFrom;
    }

    public String getDocumentBack() {
        return documentBack;
    }

    public void setDocumentBack(String documentBack) {
        this.documentBack = documentBack;
    }

    public void setRols(List<RolEntity> rols) {
        this.rols = rols;
    }

    public Integer getAdministratorManager() {
        return administratorManager;
    }

    public void setAdministratorManager(Integer administratorManager) {
        this.administratorManager = administratorManager;
    }

    @Override
    public String toString() {
        return "UserEntity{" +
                "id=" + id +
                ", username='" + username + '\'' +
                ", email='" + email + '\'' +
                ", fistName='" + fistName + '\'' +
                ", lastName='" + lastName + '\'' +
                ", documentsAprov='" + documentsAprov + '\'' +
                ", document='" + document + '\'' +
                ", city='" + city + '\'' +
                ", country='" + country + '\'' +
                ", postal='" + postal + '\'' +
                ", aboutme='" + aboutme + '\'' +
                ", password='" + password + '\'' +
                ", moneyclean=" + moneyclean +
                ", status=" + status +
                ", foto='" + foto + '\'' +
                ", documentFrom='" + documentFrom + '\'' +
                ", documentBack='" + documentBack + '\'' +
                ", rols=" + rols +
                '}';
    }

    /**
     *
     */
    private static final long serialVersionUID = 1L;
}

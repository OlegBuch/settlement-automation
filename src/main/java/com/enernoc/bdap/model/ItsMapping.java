package com.enernoc.bdap.model;

public class ItsMapping {

    public static class From {
        public String domain = "FLEX";
        public String subdomain = "GLOBAL";
        public String id;
    }

    public static class To {
        public String domain = "ECRM";
        public String subdomain = "GLOBAL";
        public String id;
    }

    public From from = new From();
    public To to = new To();

}

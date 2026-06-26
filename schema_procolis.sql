--
-- PostgreSQL database dump
--

\restrict qXNGUumO3vQ7Rrfr5sJDIMMGAZU7jka4Yed9hcgHMclewTaygPsE3dWhW5U73Hu

-- Dumped from database version 15.15 (Homebrew)
-- Dumped by pg_dump version 15.15 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: clean_driver_locations(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.clean_driver_locations() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM driver_locations 
    WHERE recorded_at < NOW() - INTERVAL '7 days';
END;
$$;


--
-- Name: update_parcel_status_on_payment(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_parcel_status_on_payment() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        UPDATE parcels 
        SET payment_status = 'paid',
            status = 'confirmed'
        WHERE id = NEW.parcel_id;
    END IF;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bids (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    parcel_id uuid NOT NULL,
    driver_id uuid NOT NULL,
    driver_name character varying(255) NOT NULL,
    driver_phone character varying(50) NOT NULL,
    price numeric(10,2) NOT NULL,
    message text,
    status character varying(50) DEFAULT 'pending'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    responded_at timestamp without time zone,
    response_message text
);


--
-- Name: TABLE bids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.bids IS 'Offres des chauffeurs pour les colis en libre service';


--
-- Name: COLUMN bids.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.bids.status IS 'pending, accepted, rejected';


--
-- Name: driver_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_locations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    driver_id uuid NOT NULL,
    latitude numeric(10,8) NOT NULL,
    longitude numeric(11,8) NOT NULL,
    accuracy numeric(10,2),
    speed numeric(10,2),
    bearing numeric(10,2),
    recorded_at timestamp without time zone DEFAULT now()
);


--
-- Name: garages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.garages (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    city character varying(100) NOT NULL,
    region character varying(100) NOT NULL,
    address text,
    phone character varying(50),
    latitude numeric(10,8),
    longitude numeric(11,8),
    drivers_count integer DEFAULT 0,
    parcels_count integer DEFAULT 0,
    revenue numeric(10,2) DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: otp_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.otp_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    code character varying(6) NOT NULL,
    type character varying(50) NOT NULL,
    phone character varying(50),
    email character varying(255),
    is_used boolean DEFAULT false,
    attempts integer DEFAULT 0,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: otps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.otps (
    id uuid NOT NULL,
    user_id uuid,
    code character varying(10) NOT NULL,
    type character varying(50) DEFAULT 'verification'::character varying,
    expires_at timestamp without time zone NOT NULL,
    attempts integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: parcel_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcel_events (
    id uuid NOT NULL,
    parcel_id uuid,
    status character varying(50) NOT NULL,
    description text,
    location character varying(255),
    user_id uuid,
    user_name character varying(255),
    metadata jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    location_lat character varying(50),
    location_lng character varying(50),
    user_role character varying(50),
    photo_url text
);


--
-- Name: parcel_photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcel_photos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    parcel_id uuid,
    url text NOT NULL,
    thumbnail_url text,
    uploaded_at timestamp without time zone DEFAULT now()
);


--
-- Name: parcels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcels (
    id uuid NOT NULL,
    tracking_number character varying(50) NOT NULL,
    sender_id uuid,
    sender_name character varying(255) NOT NULL,
    sender_phone character varying(50) NOT NULL,
    receiver_name character varying(255) NOT NULL,
    receiver_phone character varying(50) NOT NULL,
    receiver_email character varying(255),
    description text,
    weight numeric(10,2),
    type character varying(50) DEFAULT 'package'::character varying,
    status character varying(50) DEFAULT 'pending'::character varying,
    departure_garage_id uuid,
    departure_garage_name character varying(255),
    arrival_garage_id uuid,
    arrival_garage_name character varying(255),
    driver_id uuid,
    driver_name character varying(255),
    driver_phone character varying(50),
    price numeric(10,2),
    payment_method character varying(50),
    payment_status character varying(50) DEFAULT 'pending'::character varying,
    signature_url text,
    pickup_date timestamp without time zone,
    delivery_date timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    receiver_address text,
    length numeric(10,2),
    width numeric(10,2),
    height numeric(10,2),
    is_insured boolean DEFAULT false,
    insurance_amount numeric(10,2),
    is_urgent boolean DEFAULT false,
    urgent_fee numeric(10,2),
    notes text,
    estimated_delivery_date timestamp without time zone,
    created_by uuid,
    cancelled_by uuid,
    cancellation_reason text,
    cancelled_at timestamp without time zone,
    delivery_fees numeric(10,2),
    total_amount numeric(10,2),
    sender_email character varying(255),
    payment_phone_number character varying(50),
    created_by_name character varying(255),
    is_free_for_bidding boolean DEFAULT false,
    proposed_price numeric(10,2),
    negotiated_price numeric(10,2),
    selected_bid_id uuid,
    photo_urls text[] DEFAULT '{}'::text[],
    video_urls text[] DEFAULT '{}'::text[],
    audio_urls text[] DEFAULT '{}'::text[]
);


--
-- Name: COLUMN parcels.is_free_for_bidding; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.parcels.is_free_for_bidding IS 'Indique si le colis est en libre service (marchandage)';


--
-- Name: COLUMN parcels.proposed_price; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.parcels.proposed_price IS 'Prix suggéré par le client pour le libre service';


--
-- Name: COLUMN parcels.negotiated_price; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.parcels.negotiated_price IS 'Prix négocié final après acceptation d une offre';


--
-- Name: COLUMN parcels.selected_bid_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.parcels.selected_bid_id IS 'ID de l offre acceptée pour ce colis';


--
-- Name: COLUMN parcels.photo_urls; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.parcels.photo_urls IS 'Tableau des URLs des photos';


--
-- Name: COLUMN parcels.video_urls; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.parcels.video_urls IS 'Tableau des URLs des vidéos';


--
-- Name: payment_methods_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_methods_config (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    method character varying(50) NOT NULL,
    is_enabled boolean DEFAULT true,
    fees_percentage numeric(5,2) DEFAULT 0,
    fixed_fees numeric(10,2) DEFAULT 0,
    min_amount numeric(10,2) DEFAULT 0,
    max_amount numeric(10,2),
    config jsonb,
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    parcel_id uuid,
    amount numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'XOF'::character varying,
    method character varying(50) NOT NULL,
    status character varying(50) DEFAULT 'pending'::character varying,
    transaction_id character varying(255),
    phone_number character varying(50),
    reference character varying(255),
    metadata jsonb,
    created_at timestamp without time zone DEFAULT now(),
    completed_at timestamp without time zone
);


--
-- Name: tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tokens (
    id uuid NOT NULL,
    user_id uuid,
    token text NOT NULL,
    refresh_token text,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: user_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    refresh_token text NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    email character varying(255) NOT NULL,
    phone character varying(50) NOT NULL,
    full_name character varying(255) NOT NULL,
    password_hash character varying(255),
    role character varying(50) DEFAULT 'client'::character varying,
    status character varying(50) DEFAULT 'active'::character varying,
    address text,
    city character varying(100),
    region character varying(100),
    vehicle_plate character varying(50),
    vehicle_model character varying(100),
    driver_status character varying(50),
    pin character varying(10),
    gender character varying(20),
    garage_id uuid,
    profile_photo text,
    is_email_verified boolean DEFAULT false,
    is_phone_verified boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_login timestamp without time zone,
    vehicle_color character varying(50),
    vehicle_year integer,
    country character varying(100) DEFAULT 'Sénégal'::character varying,
    birth_date date,
    national_id character varying(100),
    emergency_contact character varying(255),
    emergency_phone character varying(50),
    fcm_token text,
    is_approved boolean DEFAULT false,
    approved_by uuid,
    approved_at timestamp without time zone,
    created_by uuid,
    last_active timestamp without time zone,
    garage_name character varying(255),
    is_profile_complete boolean DEFAULT false,
    rating numeric(3,2),
    total_deliveries integer DEFAULT 0,
    completed_deliveries integer DEFAULT 0,
    cancelled_deliveries integer DEFAULT 0,
    last_active_at timestamp without time zone
);


--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    plate_number character varying(50) NOT NULL,
    model character varying(100) NOT NULL,
    type character varying(50) NOT NULL,
    capacity integer NOT NULL,
    garage_id uuid,
    driver_id uuid,
    is_available boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: bids bids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bids
    ADD CONSTRAINT bids_pkey PRIMARY KEY (id);


--
-- Name: driver_locations driver_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_locations
    ADD CONSTRAINT driver_locations_pkey PRIMARY KEY (id);


--
-- Name: garages garages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.garages
    ADD CONSTRAINT garages_pkey PRIMARY KEY (id);


--
-- Name: otp_codes otp_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otp_codes
    ADD CONSTRAINT otp_codes_pkey PRIMARY KEY (id);


--
-- Name: otps otps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otps
    ADD CONSTRAINT otps_pkey PRIMARY KEY (id);


--
-- Name: parcel_events parcel_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_events
    ADD CONSTRAINT parcel_events_pkey PRIMARY KEY (id);


--
-- Name: parcel_photos parcel_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_photos
    ADD CONSTRAINT parcel_photos_pkey PRIMARY KEY (id);


--
-- Name: parcels parcels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcels
    ADD CONSTRAINT parcels_pkey PRIMARY KEY (id);


--
-- Name: parcels parcels_tracking_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcels
    ADD CONSTRAINT parcels_tracking_number_key UNIQUE (tracking_number);


--
-- Name: payment_methods_config payment_methods_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_methods_config
    ADD CONSTRAINT payment_methods_config_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (id);


--
-- Name: tokens tokens_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_token_key UNIQUE (token);


--
-- Name: user_tokens user_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);


--
-- Name: vehicles vehicles_plate_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_plate_number_key UNIQUE (plate_number);


--
-- Name: idx_bids_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bids_created_at ON public.bids USING btree (created_at);


--
-- Name: idx_bids_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bids_driver_id ON public.bids USING btree (driver_id);


--
-- Name: idx_bids_parcel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bids_parcel_id ON public.bids USING btree (parcel_id);


--
-- Name: idx_bids_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bids_status ON public.bids USING btree (status);


--
-- Name: idx_driver_locations_driver; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_driver_locations_driver ON public.driver_locations USING btree (driver_id);


--
-- Name: idx_driver_locations_recorded; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_driver_locations_recorded ON public.driver_locations USING btree (recorded_at);


--
-- Name: idx_events_parcel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_events_parcel_id ON public.parcel_events USING btree (parcel_id);


--
-- Name: idx_otp_codes_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_otp_codes_code ON public.otp_codes USING btree (code);


--
-- Name: idx_otp_codes_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_otp_codes_user ON public.otp_codes USING btree (user_id);


--
-- Name: idx_parcels_free_bidding; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_parcels_free_bidding ON public.parcels USING btree (is_free_for_bidding, status, driver_id) WHERE ((is_free_for_bidding = true) AND ((status)::text = 'free'::text) AND (driver_id IS NULL));


--
-- Name: idx_parcels_is_insured; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_parcels_is_insured ON public.parcels USING btree (is_insured);


--
-- Name: idx_parcels_is_urgent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_parcels_is_urgent ON public.parcels USING btree (is_urgent);


--
-- Name: idx_parcels_payment_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_parcels_payment_status ON public.parcels USING btree (payment_status);


--
-- Name: idx_parcels_proposed_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_parcels_proposed_price ON public.parcels USING btree (proposed_price) WHERE (proposed_price IS NOT NULL);


--
-- Name: idx_payments_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payments_created ON public.payments USING btree (created_at);


--
-- Name: idx_payments_parcel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payments_parcel ON public.payments USING btree (parcel_id);


--
-- Name: idx_payments_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payments_status ON public.payments USING btree (status);


--
-- Name: idx_payments_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payments_user ON public.payments USING btree (user_id);


--
-- Name: payments trigger_payment_completed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_payment_completed AFTER UPDATE ON public.payments FOR EACH ROW WHEN ((((new.status)::text = 'completed'::text) AND ((old.status)::text <> 'completed'::text))) EXECUTE FUNCTION public.update_parcel_status_on_payment();


--
-- Name: bids bids_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bids
    ADD CONSTRAINT bids_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.users(id);


--
-- Name: bids bids_parcel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bids
    ADD CONSTRAINT bids_parcel_id_fkey FOREIGN KEY (parcel_id) REFERENCES public.parcels(id) ON DELETE CASCADE;


--
-- Name: otps otps_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otps
    ADD CONSTRAINT otps_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: parcel_events parcel_events_parcel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_events
    ADD CONSTRAINT parcel_events_parcel_id_fkey FOREIGN KEY (parcel_id) REFERENCES public.parcels(id) ON DELETE CASCADE;


--
-- Name: parcel_events parcel_events_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_events
    ADD CONSTRAINT parcel_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: parcels parcels_arrival_garage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcels
    ADD CONSTRAINT parcels_arrival_garage_id_fkey FOREIGN KEY (arrival_garage_id) REFERENCES public.garages(id);


--
-- Name: parcels parcels_departure_garage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcels
    ADD CONSTRAINT parcels_departure_garage_id_fkey FOREIGN KEY (departure_garage_id) REFERENCES public.garages(id);


--
-- Name: parcels parcels_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcels
    ADD CONSTRAINT parcels_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.users(id);


--
-- Name: parcels parcels_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcels
    ADD CONSTRAINT parcels_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: tokens tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict qXNGUumO3vQ7Rrfr5sJDIMMGAZU7jka4Yed9hcgHMclewTaygPsE3dWhW5U73Hu

